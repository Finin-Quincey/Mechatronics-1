classdef gripper < handle
    %The gripper's purpose is to grab and release a cup. 
    %It has two modes: Open or Close.
    %Powered by a solenoid.
    
    properties
        %Arduino
        a
        %Pins
        solenoidPin
    end
    
    methods
        %Constructor
        function this = gripper(a, solenoidPin)
            
            this.a=a;
            this.solenoidPin=solenoidPin;
            
            %Automatically configure the Analog Pin
            configurePin(this.a, this.solenoidPin, "DigitalOutput");
            
        end
        
        function [] = release(this.solenoidPin)
            %RELEASE will open up the claws of the gripper
         
            digitalWrite(this.solenoidPin, LOW);       %Switch Solenoid OFF
            
            
        function []= grab(this.solenoidPin)
            %GRAB will open up the claws of the gripper.
            
            digitalWrite(this.solenoidPin, HIGH);      %Switch Solenoid ON
            
            end
        end
    end

