classdef armPins < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pulsePin %PWM
        bluePin % DigitalOutput
        yellowPin % DigitalOutput
        pinkPin % DigitalOutput
        orangePin % DigitalOutput
    end
    
    methods
        function [] = print(this)
            % Utility method to print out the pins, in case we forget!
            fprintf("   blue    yellow      pulse    pink       orange  \n");
            fprintf("X: %s        %s           %s       %s            %s \n", this.bluePin, this.yellowPin, this.pulsePin, this.pinkPin, this.orangePin);
            fprintf("Y: %s        %s           %s       %s            %s \n", this.bluePin, this.yellowPin, this.pulsePin, this.pinkPin, this.orangePin);
        end
    end
end

