classdef gantry < handle
    
    % The gantry class represents a 2-axis gantry controlled by 2 stepper
    % motors, each with an enable, direction and pulse signal.
    % Upon creation, a gantry object will set up the specified Arduino pins
    % automatically (no more accidental moving as soon as you connect...!)
    % For now this is single-speed. See test_scripts/objectGantryTest.m for
    % an example of how to use this class.
    
    % Public fields
    properties
        a % Arduino
        mode = gantryMode.MANUAL;
    end
    
    % Private fields
    properties (SetAccess = private)
        
        % Pins
        pulsePin
        xEnPin
        xDirPin
        xSwPin
        yEnPin
        yDirPin
        ySwPin
        
        pollFreq = 20; % Poll frequency in Hz, only used in MANUAL mode
        
        % State variables
        pos = [nan, nan];
        destination = [nan, nan];
        motion = [0, 0];
        
        % Calibration
        limits = [nan, nan];
        
    end
    
    % Public methods
    methods
       
        % Constructor
        function this = gantry(a, tonePin, xEnablePin, xDirectionPin, xSwitchPin, yEnablePin, yDirectionPin, ySwitchPin)
            
            % Init fields
            this.a = a;
            
            this.pulsePin = tonePin;
            this.xEnPin = xEnablePin;
            this.xDirPin = xDirectionPin;
            this.xSwPin = xSwitchPin;
            this.yEnPin = yEnablePin;
            this.yDirPin = yDirectionPin;
            this.ySwPin = ySwitchPin;
            
            % Auto-configure pins because why not
            configurePin(this.a, this.pulsePin, "PWM");
            writePWMDutyCycle(this.a, this.pulsePin, 0.5);
            configurePin(this.a, this.xEnPin, "DigitalOutput");
            configurePin(this.a, this.xDirPin, "DigitalOutput");
            configurePin(this.a, this.xSwPin, "DigitalInput");
            configurePin(this.a, this.yEnPin, "DigitalOutput");
            configurePin(this.a, this.yDirPin, "DigitalOutput");
            configurePin(this.a, this.ySwPin, "DigitalInput");
            
            this.stop; % Make sure it doesn't move yet
            
        end
        
        function [] = pins(this)
            % Utility method to print out the pins, in case we forget!
            fprintf("Gantry control pins:\n");
            fprintf("Pulse: %s\n", this.pulsePin);
            fprintf("   Enable    Direction    Terminal Switch\n");
            fprintf("X: %s        %s           %s\n", this.xEnPin, this.xDirPin, this.xSwPin);
            fprintf("Y: %s        %s           %s\n", this.yEnPin, this.yDirPin, this.ySwPin);
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
            writeDigitalPin(this.a, this.xEnPin, 1);
            this.motion(1) = 0;
        end
        
        function [] = stopY(this)
            % Stops the gantry y axis
            writeDigitalPin(this.a, this.yEnPin, 1);
            this.motion(2) = 0;
        end
        
        function [] = startX(this, dir)
            % Starts the gantry x axis in the given direction
            writeDigitalPin(this.a, this.xEnPin, 0);
            writeDigitalPin(this.a, this.xDirPin, dir);
            this.motion(1) = dir * 2 - 1;
        end
        
        function [] = startY(this, dir)
            % Starts the gantry y axis in the given direction
            writeDigitalPin(this.a, this.yEnPin, 0);
            writeDigitalPin(this.a, this.yDirPin, dir);
            this.motion(2) = dir * 2 - 1;
        end
        
        function [] = start(this, direction)
            
            % Starts the gantry moving in the given direction (see the
            % direction enum class)
            
            if sum(isnan(this.limits)) ~= 0
                error("Gantry not calibrated yet!");
            end
            
            this.destination = [nan, nan];
            
            if ~isnan(direction.x)
                this.startX(direction.x);
            else
                this.stopX;
            end
            
            if ~isnan(direction.y)
                this.startY(direction.y);
            else
                this.stopY;
            end
            
            if this.mode == gantryMode.MANUAL
                this.manualUpdate();
            end
            
        end
        
        function this = move(this, x, y)
            % Moves the gantry by the given displacement
            this.moveTo(this.pos(1) + x, this.pos(2) + y);
        end
        
        function this = moveTo(this, x, y)
            
            % Moves the gantry to the given position
            
            this.destination = [x, y];
            
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
            
            hasDestination = sum(isnan(this.destination)) == 0;
            
            % Stop x axis if it hits the limits
            if (this.motion(1) < 0 && this.pos(1) == 0) || (this.motion(1) > 0 && this.pos(1) == this.limits(1))
                this.stopX;
            end
            
            % Stop y axis if it hits the limits
            if (this.motion(2) < 0 && this.pos(2) == 0) || (this.motion(2) > 0 && this.pos(2) == this.limits(2))
                this.stopY;
            end
            
            if hasDestination
                
                if this.destination(1) == this.pos(1)
                    this.stopX; % Stop x if we're at the destination x
                else
                    % Otherwise start x towards destination
                    this.startX(this.destination(1) > this.pos(1));
                end
                
                if this.destination(2) == this.pos(2)
                    this.stopY; % Stop y if we're at the destination y
                else
                    % Otherwise start y towards destination
                    this.startY(this.destination(2) > this.pos(2));
                end
            end
            
            this.pos = this.pos + this.motion;
                
        end
        
        function [this, dist] = home(this)
            
            % Returns the gantry to its home position and optionally
            % returns the number of updates each axis was active for
            
            writeDigitalPin(this.a, this.xDirPin, 0);
            writeDigitalPin(this.a, this.xEnPin, 0);
            writeDigitalPin(this.a, this.yDirPin, 0);
            writeDigitalPin(this.a, this.yEnPin, 0);
            
            dist = [0, 0];
            
            xHomed = false;
            yHomed = false;
            
            while true
                
                tic;
                
                xSwOpen = readDigitalPin(this.a, this.xSwPin);
                ySwOpen = readDigitalPin(this.a, this.ySwPin);
                
                if xSwOpen && ~xHomed
                    dist(1) = dist(1) + 1;
                else
                    stopX(this);
                    xHomed = true;
                end
                
                if ySwOpen && ~yHomed
                    dist(2) = dist(2) + 1;
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
            % Release the motor so it's not doing any braking
            writePWMDutyCycle(this.a, this.pulsePin, 1);
            
            response = questdlg("Move gantry manually to NE corner and click 'Done'", "Gantry Calibration", "Done", "Cancel", "Done");
            
            writePWMDutyCycle(this.a, this.pulsePin, 0.5);
            
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