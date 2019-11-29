classdef armPins < handle
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        pulse
    end
    
    methods
        function [] = print(this)
            % Utility method to print out the pins, in case we forget!
            fprintf("Pulse: %s\n", this.pulse);
        end
    end
end

