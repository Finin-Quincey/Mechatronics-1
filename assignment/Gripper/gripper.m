classdef gripper < handle
    
    % The gripper's purpose is to grab and release a cup. 
    % It has two modes: Open or Close.
    % Powered by a solenoid.
    
    properties
        % Arduino
        a
        % Pins
        solenoidPin
    end
    
    methods
        
        % Constructor
        function this = gripper(a, solenoidPin)
            
            this.a = a;
            this.solenoidPin = solenoidPin;
            
            % Automatically configure the output pin
            configurePin(this.a, this.solenoidPin, "DigitalOutput");
            
        end
        
        function [] = release(this)
            % RELEASE will open up the claws of the gripper
         
            writeDigitalPin(this.solenoidPin, 0);       % Switch Solenoid OFF
            
        end
            
        function [] = grab(this)
            % GRAB will open up the claws of the gripper.
            
            writeDigitalPin(this.solenoidPin, 1);      % Switch Solenoid ON
            
        end
    end
end

