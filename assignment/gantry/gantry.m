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
        minDC = 0.05; % PWM duty cycle required for maximum oscillator frequency
        maxDC = 1; % PWM duty cycle for minimum oscillator frequency
        minVcont = 0.8; % Min achievable voltage from filter
        maxVcont = 4.5; % Max achievable voltage from filter
        
        % Oscillator circuit parameters
        Vcc = 5; % Supply voltage (5V)
        C = 1e-6; % Capacitance in Farads
        R1 = 4700; % Resistor 1, 4.7kOhms
        R2 = 33; % Resistor 2, 33Ohms
        
        % Gantry data
        distancePerPulse = 0.0292;
        slowDownDist = 3;
        
    end
    
    % Public fields
    properties
        a % Arduino
        mode = gantryMode.MANUAL;
    end
    
    % Private fields
    properties (SetAccess = private)
        
        pins; % Pin configuration
        
        % Dummy rotary encoder objects for pulse counting
        xEncoder;
        yEncoder;
        
        % State variables
        pos = [0, 0];
        destination = [nan, nan];
        motion = [0, 0]; % Which direction each axis is currently moving: 1 = forwards, -1 = backwards, 0 = off
        maxSpeed = 30; % Max speed during a movement in mm/s
        
        % Calibration
        limits = [nan, nan];
        
        % Conversion functions
        DCtoFreq;
        freqToDC;
        
    end
    
    % Public methods
    methods
       
        % Constructor
        function this = gantry(a, pins)
            
            % Init fields
            this.a = a;
            
            this.pins = pins;
            
            % Auto-configure pins
            configurePin(this.a, this.pins.xPls, "PWM");
            writePWMDutyCycle(this.a, this.pins.xPls, gantry.maxDC);
            configurePin(this.a, this.pins.xEn, "DigitalOutput");
            configurePin(this.a, this.pins.xDir, "DigitalOutput");
            configurePin(this.a, this.pins.xSw, "DigitalInput");
            configurePin(this.a, this.pins.xInt1, "Interrupt");
            configurePin(this.a, this.pins.xInt2, "Interrupt");
            
            configurePin(this.a, this.pins.yPls, "PWM");
            writePWMDutyCycle(this.a, this.pins.yPls, gantry.maxDC);
            configurePin(this.a, this.pins.yEn, "DigitalOutput");
            configurePin(this.a, this.pins.yDir, "DigitalOutput");
            configurePin(this.a, this.pins.ySw, "DigitalInput");
            configurePin(this.a, this.pins.yInt1, "Interrupt");
            configurePin(this.a, this.pins.yInt2, "Interrupt");
            
            % Set up encoder objects
            this.xEncoder = rotaryEncoder(a, this.pins.xInt1, this.pins.xInt2);
            this.yEncoder = rotaryEncoder(a, this.pins.yInt1, this.pins.yInt2);
            
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
        
        function [dc] = velocityToDC(this, v)
            % Converts the given velocity to a pulse pin duty cycle (sign
            % is ignored)
            dc = double(this.freqToDC(max(abs(v), 1) / gantry.distancePerPulse));
            dc = min(max(dc, 0), 1); % Clamp to between 0 and 1
        end
        
        function [speed] = DCtoSpeed(this, dc)
            % Converts the given pulse pin duty cycle to a speed
            dc = min(max(dc, 0), 1); % Clamp to between 0 and 1
            speed = double(this.DCtoFreq(dc)) * gantry.distancePerPulse;
        end
        
        function [] = printPins(this)
            % Utility method to print out the pins, in case we forget!
            fprintf("Gantry control pins:\n");
            this.pins.print();
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
            result = sum(abs(this.motion)) > 0;
        end
        
        function this = setSpeed(this, speed)
            % Sets the speed of the gantry in mm/s
            if speed > this.DCtoSpeed(gantry.minDC)
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
        end
        
        function [] = stopX(this)
            % Stops the gantry x axis
            writePWMDutyCycle(this.a, this.pins.xPls, this.maxDC); % Set to minimum speed
            this.motion(1) = 0;
            pause(0.01);
            writeDigitalPin(this.a, this.pins.xEn, 1);
            resetCount(this.xEncoder);
        end
        
        function [] = stopY(this)
            % Stops the gantry y axis
            writePWMDutyCycle(this.a, this.pins.yPls, this.maxDC); % Set to minimum speed
            this.motion(2) = 0;
            pause(0.01);
            writeDigitalPin(this.a, this.pins.yEn, 1);
            resetCount(this.yEncoder);
        end
        
        function [] = startX(this, dir)
            % Starts the gantry x axis in the given direction
            % N.B. This only operates the enable/direction pins, not pulse
            writeDigitalPin(this.a, this.pins.xDir, dir);
            this.motion(1) = dir * 2 - 1;
            pause(0.01);
            writeDigitalPin(this.a, this.pins.xEn, 0);
        end
        
        function [] = startY(this, dir)
            % Starts the gantry y axis in the given direction
            % N.B. This only operates the enable/direction pins, not pulse
            writeDigitalPin(this.a, this.pins.yDir, dir);
            this.motion(2) = dir * 2 - 1;
            pause(0.01);
            writeDigitalPin(this.a, this.pins.yEn, 0);
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
            % Will error if the position is outside the movement limits
            
            if sum(isnan(this.limits)) ~= 0
                error("Gantry not calibrated yet!");
            end
            
            if sum([x, y] > this.limits) + sum(this.destination < [0, 0]) ~= 0
                error("Destination out of bounds!");
            end
            
            this.moveToInternal(x, y);
            
        end
        
        function this = update(this)
            
            % Updates the gantry
            % In programmed mode, this must be called from the main script
            % n times a second (n=20 works well)
            
            dx = readCount(this.xEncoder, "Reset", true) * this.distancePerPulse;
            dy = readCount(this.yEncoder, "Reset", true) * this.distancePerPulse;
            
            % Update the position of the gantry
            if this.isMoving
                this.pos = this.pos + this.motion .* [dx, dy];
            end
            
            hasDestination = sum(isnan(this.destination)) == 0;
            
            % Stop x axis if it hits the limits
            if (this.motion(1) < 0 && this.pos(1) <= 0) || (this.motion(1) > 0 && this.pos(1) >= this.limits(1))
                this.stopX;
            end
            
            % Stop y axis if it hits the limits
            if (this.motion(2) < 0 && this.pos(2) <= 0) || (this.motion(2) > 0 && this.pos(2) >= this.limits(2))
                this.stopY;
            end
            
            if hasDestination
                
                travelLeft = this.destination - this.pos;
                
                if travelLeft(1) * this.motion(1) <= gantry.slowDownDist
                   writePWMDutyCycle(this.a, this.pins.xPls, gantry.maxDC);
                end
                
                if travelLeft(2) * this.motion(2) <= gantry.slowDownDist
                   writePWMDutyCycle(this.a, this.pins.yPls, gantry.maxDC);
                end
                
                if travelLeft(1) * this.motion(1) <= 0
                    this.stopX;
                end
                
                if travelLeft(2) * this.motion(2) <= 0
                    this.stopY;
                end
                
            end
            
        end
        
        function [this, dist] = home(this)
            
            % Homes the gantry (2-pass)
            % Returns the gantry to its home position and optionally
            % returns the number of updates each axis was active for
            
            [~, dist] = this.homeInternal(this.maxSpeed);
            this.moveToInternal(25, 25);
            this.manualUpdate;
            this.homeInternal(10);
            
        end
        
        function this = calibrate(this)
            % Simple gantry calibration
            % Allows the user to move the gantry to its end-of-travel, then
            % re-homes it and records the time taken to do so.
            this.stop;
            
            response = questdlg("Move gantry manually to NE corner and click 'Done'", "Gantry Calibration", "Done", "Cancel", "Done");
            
            if response == "Done"
                [~, this.limits] = this.home;
            end
        end
        
    end
    
    % Private methods
    methods (Access = private)
        
        function [this, dist] = homeInternal(this, speed)
            
            % Internal home function (single-pass)
            % Returns the gantry to its home position and optionally
            % returns the number of updates each axis was active for
            
            resetCount(this.xEncoder);
            resetCount(this.yEncoder);
            
            this.startX(0);
            this.startY(0);
            
            writePWMDutyCycle(this.a, this.pins.xPls, this.velocityToDC(speed));
            writePWMDutyCycle(this.a, this.pins.yPls, this.velocityToDC(speed));
            
            dist = [0, 0];
            
            xHomed = false;
            yHomed = false;
            
            while true
                
                tic;
                
                xSwOpen = readDigitalPin(this.a, this.pins.xSw);
                ySwOpen = readDigitalPin(this.a, this.pins.ySw);
                
                if ~xSwOpen && ~xHomed
                    dist(1) = readCount(this.xEncoder) * this.distancePerPulse;
                    stopX(this);
                    xHomed = true;
                end
                
                if ~ySwOpen && ~yHomed
                    dist(2) = readCount(this.yEncoder) * this.distancePerPulse;
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
        
        function this = moveToInternal(this, x, y)
            
            % Moves the gantry to the given position
            % INTERNAL METHOD WITH NO SAFETY CHECKS!
            
            this.destination = [x, y];
            
            resetCount(this.xEncoder);
            resetCount(this.yEncoder);
            
            travel = abs(this.destination - this.pos);
            
            if travel(1) > gantry.slowDownDist
                this.startX(this.destination(1) > this.pos(1));
            end
            
            if travel(2) > gantry.slowDownDist
                this.startY(this.destination(2) > this.pos(2));
            end
            
            if travel(1) == travel(2)
                velocity = [this.maxSpeed, this.maxSpeed];
            elseif travel(1) > travel(2)
                velocity = [this.maxSpeed, this.maxSpeed * (travel(2)/travel(1))];
            else
                velocity = [this.maxSpeed * (travel(1)/travel(2)), this.maxSpeed];
            end
            
            writePWMDutyCycle(this.a, this.pins.xPls, this.velocityToDC(velocity(1)));
            writePWMDutyCycle(this.a, this.pins.yPls, this.velocityToDC(velocity(2)));
            
            if this.mode == gantryMode.MANUAL
                this.manualUpdate();
            end
            
        end
        
        function this = manualUpdate(this)
            % Internal function to update the gantry while moving in manual
            % mode
            while true
                
                t = tic;
                
                this.update();
                
                if ~this.isMoving
                    break;
                end
                
                while toc(t) < 1/this.pollFreq
                    pause(0.00001);
                end
                
            end
        end
        
    end
    
end