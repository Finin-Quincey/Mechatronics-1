classdef arm < handle
    
    % ARM controls the height of the gripper.
    % Programmed to be set in 3 different positions: low, high and drop cup.
    % Powered by an RC servo motor.
    
    % Constants
    properties (Constant)
        
        forwardDC = 0.2;
        forwardSpeed = 300; % deg/s
        reverseDC = 0.22;
        reverseSpeed = 145; % deg/s
        offDC = 0.21;
        
        minRotTime = 0.3; %s
        
        % THESE NEED CALIBRATING!
        singleCupHeight = 30; % mm
        cupVerticalSpacing = 10; % mm
        
    end
    
    % Public fields
    properties
        a % Arduino
    end
    
    % Private fields
    properties (SetAccess = private)
        
        % Pins
        pulsePin; % PWM
        
        % State variables
        currentAngle = 0; % 0 is UP
        
    end
    
    methods
        
        % Constructor
        function this = arm(a, pulsePin)
            
            this.a = a;
            this.pulsePin = pulsePin;
            
            % Automatically configure the pulse pin
            configurePin(this.a, this.pulsePin, "PWM");
            writePWMDutyCycle(this.a, this.pulsePin, arm.offDC);
            
        end
        
        function [] = printPins(this)
            % Utility method to print out the pins, in case we forget!
            fprintf("Arm control pin (PWM): %s\n", this.pulsePin);
        end
        
        function this = up(this)
            % Moves the arm up to its highest position (clearance)
            this.rotateTo(0);
        end
        
        function this = down(this)
            % Moves the arm down to its lowest position (sensing)
            this.rotateTo(180);
        end
        
        function this = pickupHeight(this, n)
            % Moves the arm to the appropriate height to pick up a cup from
            % the top of a stack of n cups
            this.rotateTo();
        end
        
        function this = stopMotor(this)
            % Stops the motor
            writePWMDutyCycle(this.a, this.pulsePin, arm.offDC);
        end
        
        function this = rotateTo(this, angle)
            
            this.rotateMotor(angle - this.currentAngle);
            
        end
        
        function this = rotateMotor(this, angle)
            
            tic;
            
            if angle < 0
                t = abs(angle)/arm.reverseSpeed;
            else
                t = abs(angle)/arm.forwardSpeed;
            end
            
            if t < arm.minRotTime
                error("Angle too small!");
            end
            
            if angle < 0
                writePWMDutyCycle(this.a, this.pulsePin, arm.reverseDC);
            else
                writePWMDutyCycle(this.a, this.pulsePin, arm.forwardDC);
            end
            
            pause(t - toc);
            
            writePWMDutyCycle(this.a, this.pulsePin, arm.offDC);
            
            this.currentAngle = this.currentAngle + angle;
            
        end
        
    end
end
