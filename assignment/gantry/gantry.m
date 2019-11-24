classdef gantry < handle
    
    % The gantry class represents a 2-axis gantry controlled by 2 stepper
    % motors, each with an enable, direction and pulse signal.
    % Upon creation, a gantry object will set up the specified Arduino pins
    % automatically (no more accidental moving as soon as you connect...!)
    % This class now handles speed control using dual FM oscillator
    % circuits (PWM through a low-pass filter supplying the control voltage
    % for a 555 timer in astable mode). See test_scripts/objectGantryTest.m
    % for an example of how to use this class.
    
    % Constants
    properties (Constant)
        
        pollFreq = 20; % Poll frequency in Hz, only used in MANUAL mode
        
        % Low pass filter characteristics
        minDC = 0.02; % PWM duty cycle required for maximum oscillator frequency
        maxDC = 1; % PWM duty cycle for minimum oscillator frequency
        minVcont = 0.8; % Min achievable voltage from filter
        maxVcont = 4.5; % Max achievable voltage from filter
        
        % Oscillator circuit parameters
        Vcc = 5; % Supply voltage (5V)
        C = 1e-6; % Capacitance in Farads
        R1 = 5000; % Resistor 1, 5kOhms
        R2 = 30; % Resistor 2, 30Ohms
        
        % Gantry data
        motorStepAngle = deg2rad(1.8);
        pulleyRadius = 15.3; % mm
        distancePerStep = gantry.motorStepAngle * gantry.pulleyRadius; % mm
        
        % == Replaced with symbolic math toolbox ==
        
        % Conversion from PWM duty cycle to oscillator frequency, see:
        % https://electronics.stackexchange.com/questions/101530/what-is-the-equation-for-the-555-timer-control-voltage
        %DCtoFreq = @(DC) 1 / (gantry.C * (gantry.R1 + gantry.R2) * log(1 + (5 * (DC - gantry.minDC))/(2 * (5 - 5 * (DC - gantry.minDC)))) + gantry.C * gantry.R2 * log(2));
        % I used WolframAlpha to rearrange this, definitely not doing it by hand!
        %freqToDC = @(f) (2 * gantry.minDC * exp((1 - gantry.C * f * gantry.R2 * log(2))/(gantry.minDC * f * (gantry.R2 + gantry.R1))) + 2 * exp((1 - gantry.C * f * gantry.R2 * log(2))/(gantry.C * f * (gantry.R2 + gantry.R1))) - gantry.minDC - 2)/(2 * exp((1 - gantry.C * f * gantry.R2 * log(2))/(gantry.C * f * (gantry.R2 + gantry.R1))) - 1);
        
    end
    
    % Public fields
    properties
        a % Arduino
        mode = gantryMode.MANUAL;
    end
    
    % Private fields
    properties (SetAccess = private)
        
        % Pins
        xPlsPin
        xEnPin
        xDirPin
        xSwPin
        yPlsPin
        yEnPin
        yDirPin
        ySwPin
        
        % State variables
        pos = [0, 0];
        destination = [nan, nan];
        origin = [nan, nan];
        axisDirections = [0, 0]; % Which direction each axis is currently moving: 1 = forwards, -1 = backwards, 0 = off
        velocity = [0, 0]; % Current speed in x and y in mm/s
        maxSpeed = 1500; % Max speed during a movement in mm/s
        acceleration = 2000; % Acceleration of the gantry in mm/s^2
        timer = nan;
        
        % Calibration
        limits = [nan, nan];
        
        % Conversion functions
        DCtoFreq;
        freqToDC;
        
    end
    
    % Public methods
    methods
       
        % Constructor
        function this = gantry(a, xEnablePin, xDirectionPin, xPulsePin, xSwitchPin, yEnablePin, yDirectionPin, yPulsePin, ySwitchPin)
            
            % Init fields
            this.a = a;
            
            this.xPlsPin = xPulsePin;
            this.xEnPin = xEnablePin;
            this.xDirPin = xDirectionPin;
            this.xSwPin = xSwitchPin;
            this.yPlsPin = yPulsePin;
            this.yEnPin = yEnablePin;
            this.yDirPin = yDirectionPin;
            this.ySwPin = ySwitchPin;
            
            % Auto-configure pins because why not
            configurePin(this.a, this.xPlsPin, "PWM");
            writePWMDutyCycle(this.a, this.xPlsPin, 1);
            configurePin(this.a, this.xEnPin, "DigitalOutput");
            configurePin(this.a, this.xDirPin, "DigitalOutput");
            configurePin(this.a, this.xSwPin, "DigitalInput");
            configurePin(this.a, this.yPlsPin, "PWM");
            writePWMDutyCycle(this.a, this.yPlsPin, 1);
            configurePin(this.a, this.yEnPin, "DigitalOutput");
            configurePin(this.a, this.yDirPin, "DigitalOutput");
            configurePin(this.a, this.ySwPin, "DigitalInput");
            
            this.stop; % Make sure it doesn't move yet
            
            % Conversion from PWM duty cycle to oscillator frequency, see:
            % https://electronics.stackexchange.com/questions/101530/what-is-the-equation-for-the-555-timer-control-voltage
            % Using the symbolic math toolbox allows MATLAB to rearrange it
            % for us, which is nice!
            % However, it does mean we have to create it in the constructor
            % instead of the constants block.
            syms rlcFilter(DC);
            rlcFilter(DC) = gantry.minVcont + (gantry.maxVcont - gantry.minVcont) * (DC - gantry.minDC);
            syms f(DC);
            f(DC) = 1 / (gantry.C * (gantry.R1 + gantry.R2) * log(1 + (rlcFilter(DC))/(2 * (gantry.Vcc - rlcFilter(DC)))) + gantry.C * gantry.R2 * log(2));
            
            this.DCtoFreq = f;
            this.freqToDC = finverse(this.DCtoFreq);
            
        end
        
        function [dc] = velocityToDC(v)
            % Converts the given velocity to a pulse pin duty cycle (sign
            % is ignored)
            dc = double(gantry.freqToDC(max(abs(v), 1) / gantry.distancePerStep));
        end
        
        function [speed] = DCtoSpeed(dc)
            % Converts the given pulse pin duty cycle to a speed
            speed = double(gantry.DCToFreq(dc)) * gantry.distancePerStep;
        end
        
        function [] = pins(this)
            % Utility method to print out the pins, in case we forget!
            fprintf("Gantry control pins:\n");
            fprintf("   Enable    Direction    Pulse    Terminal Switch\n");
            fprintf("X: %s        %s           %s       %s\n", this.xEnPin, this.xDirPin, this.xPlsPin, this.xSwPin);
            fprintf("Y: %s        %s           %s       %s\n", this.yEnPin, this.yDirPin, this.yPlsPin, this.ySwPin);
        end
        
        function pos = whereAmI(this)
            % Returns the gantry's current position
            if sum(isnan(this.pos)) ~= 0
                error("Gantry not homed yet!");
            end
            pos = this.pos;
        end
        
        function result = isMoving(this)
            % Returns true if the gantry is moving, false if it has stopped
            result = sum(abs(this.axisDirections)) > 0;
        end
        
        function this = setSpeed(this, speed)
            % Sets the speed of the gantry in mm/s
            if speed > DCToSpeed(gantry.minDC)
                error("The given speed exceeds the maximum speed of the gantry!");
            end
            
            this.maxSpeed = speed;
        end
        
        function this = toggleMode(this)
            
            % Toggles the gantry control mode
            % Manual control mode means the gantry handles its own updates,
            % so you can operate it directly from the command window
            % without it exceeding its limits
            % Programmed mode means the gantry needs to be updated from a
            % script or function via gantry.update, allowing that script or
            % function to perform other logic while the gantry is moving
            
            if this.mode == gantryMode.MANUAL
                this.mode = gantryMode.PROGRAMMED;
            else
                this.mode = gantryMode.MANUAL;
            end
            
            fprintf("Gantry now in %s control mode\n", this.mode.name);
        end
        
        function [] = stop(this)
            % Stops all gantry movement
            stopX(this);
            stopY(this);
            % Reset the timer so we don't think it's been ages since the
            % last update when we next start moving
            this.timer = nan;
        end
        
        function [] = stopX(this)
            % Stops the gantry x axis
            writeDigitalPin(this.a, this.xEnPin, 1);
            writePWMDutyCycle(this.a, this.xPlsPin, 1); % Set to minimum speed
            this.axisDirections(1) = 0;
            this.velocity(1) = 0;
        end
        
        function [] = stopY(this)
            % Stops the gantry y axis
            writeDigitalPin(this.a, this.yEnPin, 1);
            writePWMDutyCycle(this.a, this.yPlsPin, 1); % Set to minimum speed
            this.axisDirections(2) = 0;
            this.velocity(2) = 0;
        end
        
        function [] = startX(this, dir)
            % Starts the gantry x axis in the given direction
            % N.B. This only operates the enable/direction pins, not pulse
            writeDigitalPin(this.a, this.xEnPin, 0);
            writeDigitalPin(this.a, this.xDirPin, dir);
            this.axisDirections(1) = dir * 2 - 1;
        end
        
        function [] = startY(this, dir)
            % Starts the gantry y axis in the given direction
            % N.B. This only operates the enable/direction pins, not pulse
            writeDigitalPin(this.a, this.yEnPin, 0);
            writeDigitalPin(this.a, this.yDirPin, dir);
            this.axisDirections(2) = dir * 2 - 1;
        end
        
%         function [] = start(this, direction)
%             
%             % Starts the gantry moving in the given direction (see the
%             % direction enum class)
%             
%             if sum(isnan(this.limits)) ~= 0
%                 error("Gantry not calibrated yet!");
%             end
%             
%             this.destination = [nan, nan];
%             
%             if ~isnan(direction.x)
%                 this.startX(direction.x);
%             else
%                 this.stopX;
%             end
%             
%             if ~isnan(direction.y)
%                 this.startY(direction.y);
%             else
%                 this.stopY;
%             end
%             
%             if this.mode == gantryMode.MANUAL
%                 this.manualUpdate();
%             end
%             
%         end
        
        function this = move(this, x, y)
            % Moves the gantry by the given displacement
            this.moveTo(this.pos(1) + x, this.pos(2) + y);
        end
        
        function this = moveTo(this, x, y)
            
            % Moves the gantry to the given position
            
            this.destination = [x, y];
            this.origin = this.pos; % Record where we started from
            
            totalTravel = this.destination - this.origin;
            speed = 1;
            this.velocity = totalTravel / hypot(totalTravel(1), totalTravel(2)) * speed;
            
            this.startX(this.destination(1) > this.pos(1));
            this.startY(this.destination(2) > this.pos(2));
            
            if sum(isnan(this.limits)) ~= 0
                error("Gantry not calibrated yet!");
            end
            
            if sum(this.destination > this.limits) + sum(this.destination < [0, 0]) ~= 0
                error("Destination out of bounds!");
            end
            
            if this.mode == gantryMode.MANUAL
                this.manualUpdate();
            end
            
        end
        
        function this = update(this)
            
            % Updates the gantry
            % In programmed mode, this must be called from the main script
            % n times a second (n=20 works well)
            
            if isnan(this.timer)
                timeSinceLastUpdate = 1/this.pollFreq; % Fallback for first update
            else
                timeSinceLastUpdate = toc(this.timer);
            end
            
            this.timer = tic;
            
            % Update the position of the gantry
            if this.isMoving
                this.pos = this.pos + this.velocity * timeSinceLastUpdate;
            end
            
            hasDestination = sum(isnan(this.destination)) == 0;
            
            % Stop x axis if it hits the limits
            if (this.velocity(1) < 0 && this.pos(1) == 0) || (this.velocity(1) > 0 && this.pos(1) == this.limits(1))
                this.stopX;
            end
            
            % Stop y axis if it hits the limits
            if (this.velocity(2) < 0 && this.pos(2) == 0) || (this.velocity(2) > 0 && this.pos(2) == this.limits(2))
                this.stopY;
            end
            
            if hasDestination
                
                totalTravel = this.destination - this.origin;
                travelDone = this.pos - this.origin;
                travelLeft = this.destination - this.pos;
                
                totalDist = hypot(totalTravel(1), totalTravel(2));
                distDone = hypot(travelDone(1), travelDone(2));
                distLeft = hypot(travelLeft(1), travelLeft(2));
                
                % Enable/direction pin control
                if distDone > totalDist
                    this.stop;
                end
                
                speed = min(this.maxSpeed, sqrt(2 * this.acceleration * min(distDone, distLeft)));
                
                this.velocity = totalTravel / totalDist * speed;
                              
                writePWMDutyCycle(this.a, this.xPlsPin, velocityToDC(this.velocity(1)));
                writePWMDutyCycle(this.a, this.yPlsPin, velocityToDC(this.velocity(2)));
                
            end
            
        end
        
        function [this, dist] = home(this)
            
            % Returns the gantry to its home position and optionally
            % returns the number of updates each axis was active for
            
            writeDigitalPin(this.a, this.xDirPin, 0);
            writeDigitalPin(this.a, this.xEnPin, 0);
            writeDigitalPin(this.a, this.yDirPin, 0);
            writeDigitalPin(this.a, this.yEnPin, 0);
            
            writePWMDutyCycle(this.a, this.xPlsPin, gantry.freqToDC(this.maxSpeed / gantry.distancePerStep));
            writePWMDutyCycle(this.a, this.yPlsPin, gantry.freqToDC(this.maxSpeed / gantry.distancePerStep));
            
            dist = [0, 0];
            
            xHomed = false;
            yHomed = false;
            
            while true
                
                tic;
                
                xSwOpen = readDigitalPin(this.a, this.xSwPin);
                ySwOpen = readDigitalPin(this.a, this.ySwPin);
                
                if xSwOpen && ~xHomed
                    dist(1) = dist(1) + this.maxSpeed;
                else
                    stopX(this);
                    xHomed = true;
                end
                
                if ySwOpen && ~yHomed
                    dist(2) = dist(2) + this.maxSpeed;
                else
                    stopY(this);
                    yHomed = true;
                end
                
                if xHomed && yHomed
                    this.pos = [0, 0];
                    disp("Gantry at home position");
                    return;
                end
                
                while toc < 1/this.pollFreq
                    pause(0.00001);
                end
                
            end
        end
        
        function this = calibrate(this)
            % Simple gantry calibration
            % Allows the user to move the gantry to its end-of-travel, then
            % re-homes it and records the time taken to do so.
            this.stop;
            % Release the motors so they're not doing any braking
            writePWMDutyCycle(this.a, this.xPlsPin, 1);
            writePWMDutyCycle(this.a, this.yPlsPin, 1);
            
            response = questdlg("Move gantry manually to NE corner and click 'Done'", "Gantry Calibration", "Done", "Cancel", "Done");
            
            writePWMDutyCycle(this.a, this.xPlsPin, 0.5);
            writePWMDutyCycle(this.a, this.yPlsPin, 0.5);
            
            if response == "Done"
                [~, this.limits] = this.home;
            end
        end
        
    end
    
    % Private methods
    methods (Access = private)
        
        function this = manualUpdate(this)
            % Internal function to update the gantry while moving in manual
            % mode
            while true
                
                tic;
                
                this.update();
                
                if ~this.isMoving
                    break;
                end
                
                while toc < 1/this.pollFreq
                    pause(0.00001);
                end
                
            end
        end
    end
    
end