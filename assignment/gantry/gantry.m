classdef gantry < handle
    
    % The gantry class represents a 2-axis gantry controlled by 2 stepper
    % motors, each with an enable, direction and pulse signal.
    % Upon creation, a gantry object will set up the specified Arduino pins
    % automatically (no more accidental moving as soon as you connect...!)
    % For now this is a single-speed, and you have to set the pulse input
    % manually.
    
    % Public fields
    properties
        a % Arduino
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
            
            this.stop;
            
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
        
        function [] = stop(this)
            % Stops all gantry movement
            stopX(this);
            stopY(this);
        end
        
        function [] = stopX(this)
            % Stops the gantry x axis
            writeDigitalPin(this.a, this.xEnPin, 1);
        end
        
        function [] = stopY(this)
            % Stops the gantry y axis
            writeDigitalPin(this.a, this.yEnPin, 1);
        end
        
        function [] = start(this, direction)
            % Starts the gantry moving in the given direction (see the
            % direction enum class)
            if ~isnan(direction.x)
                writeDigitalPin(this.a, this.xEnPin, 0);
                writeDigitalPin(this.a, this.xDirPin, direction.x);
            else
                writeDigitalPin(this.a, this.xEnPin, 1);
            end
            
            if ~isnan(direction.y)
                writeDigitalPin(this.a, this.yEnPin, 0);
                writeDigitalPin(this.a, this.yDirPin, direction.y);
            else
                writeDigitalPin(this.a, this.yEnPin, 1);
            end
        end
        
        function this = move(this, x, y)
            % Moves the gantry by the given vector
            
            destination = this.pos + [x, y];
            
            if sum(destination > this.limits) + sum(destination < [0, 0]) ~= 0
                error("Target position out of bounds!");
            end
            
            writeDigitalPin(this.a, this.xDirPin, x > 0);
            writeDigitalPin(this.a, this.yDirPin, y > 0);
            
            if x ~= 0
                writeDigitalPin(this.a, this.xEnPin, 0);
            end
            
            if y ~= 0
                writeDigitalPin(this.a, this.yEnPin, 0);
            end
            
            % Number of steps left to move in each direction
            dx = abs(x);
            dy = abs(y);
            
            while true
                
                tic;
                
                if dx == 0 && dy == 0
                    this.stop;
                    return;
                end
                
                if dx > 0
                    dx = dx-1;
                    this.pos(1) = this.pos(1) + sign(x);
                else
                    stopX(this);
                end
                
                if dy > 0
                    dy = dy-1;
                    this.pos(2) = this.pos(2) + sign(y);
                else
                    stopY(this);
                end
                
                while toc < 1/this.pollFreq
                    pause(0.00001);
                end
                
            end
            
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
        
    end
    
end