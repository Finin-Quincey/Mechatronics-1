classdef HallSensor < handle
    
    % HallSensor is a device that is used to measure the magnitude of a magnetic field.
    % Its output voltage is directly proportional to the magnetic field strength through it.
    % They are responsible of detecting the magnetic field of the magnets.
    
    properties
        % Pins
        VoutPin % Analog Pin
        % Arduino
        a
    end
    
    methods
        
        % Constructor
        function this = HallSensor(a, AnalogPin)
            
            this.a = a;
            this.VoutPin = AnalogPin;
            
            % Automatically configure the Analog Pin
            configurePin(this.a, this.VoutPin, "AnalogInput");
            
        end
        
        function voltages = Read(this)
          % Reads the current voltage output from the hall sensor
          voltages = readVoltage(this.a,this.VoutPin);
        end
        
        function [] = pins(this)
            
            % Utility method to print out the pins. Good tool if we forget.
            
            fprintf("Sensor Analog Pin:\n");
            fprintf("   Vin\n");
            fprintf(" %s \n",this.VoutPin);
            
        end
        
        
    end
    
end
