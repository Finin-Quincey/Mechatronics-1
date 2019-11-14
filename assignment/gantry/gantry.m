classdef gantry < handle
    
    % The gantry class represents a 2-axis gantry controlled by 2 stepper
    % motors, each with an enable, direction and pulse signal.
    % Upon creation, a Gantry object will set up the specified Arduino pins
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
        xEnPin
        xDirPin
        xSwPin
        yEnPin
        yDirPin
        ySwPin
        
        pollFreq = 100; % Poll frequency in Hz
        
        % State variables
        pos = [nan, nan];
    end
    
    % Public methods
    methods
       
        % Constructor
        function this = Gantry(a, xEnablePin, xDirectionPin, xSwitchPin, yEnablePin, yDirectionPin, ySwitchPin)
            
            % Init fields
            this.a = a;
            
            this.xEnPin = xEnablePin;
            this.xDirPin = xDirectionPin;
            this.xSwPin = xSwitchPin;
            this.yEnPin = yEnablePin;
            this.yDirPin = yDirectionPin;
            this.ySwPin = ySwitchPin;
            
            % Auto-configure pins because why not
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
            writeDigitalPin(this.a, this.xEnPin, 1);
            writeDigitalPin(this.a, this.yEnPin, 1);
        end
        
        function this = move(this, x, y)
            % Moves the gantry by the given vector
            % NB This is not calibrated yet!
            
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
                
                if dx == 0 && dy == 0
                    this.stop;
                    return;
                end
                
                if dx > 0
                    dx = dx-1;
                    this.pos(1) = this.pos(1) + sign(x);
                else
                    writeDigitalPin(this.a, this.xEnPin, 1);
                end
                
                if dy > 0
                    dy = dy-1;
                    this.pos(2) = this.pos(2) + sign(y);
                else
                    writeDigitalPin(this.a, this.yEnPin, 1);
                end
                
                pause(1/this.pollFreq);
                
            end
            
        end
        
        function this = home(this)
            % Returns the gantry to its home position
            
            writeDigitalPin(this.a, this.xDirPin, 0);
            writeDigitalPin(this.a, this.xEnPin, 0);
            writeDigitalPin(this.a, this.yDirPin, 0);
            writeDigitalPin(this.a, this.yEnPin, 0);
            
            while true
                
                xSwOpen = readDigitalPin(this.a, this.xSwPin);
                ySwOpen = readDigitalPin(this.a, this.ySwPin);
                
                if ~xSwOpen
                    writeDigitalPin(this.a, this.xEnPin, 1);
                end
                
                if ~ySwOpen
                    writeDigitalPin(this.a, this.yEnPin, 1);
                end
                
                if ~xSwOpen && ~ySwOpen
                    this.pos = [0, 0];
                    disp("Gantry at home position");
                    return;
                end
                
            end
        end
        
        function this = calibrate(this)
            % Simple gantry calibration
            % Moves the gantry to a predefined point and allows the user
            % to enter its true coordinates (as measured with a ruler),
            % then adjusts this gantry object's scale factor appropriately
        end
        
    end
    
    % Private methods
    methods (Access = private)
        
    end
    
end