classdef gantryPins < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        xPls
        xEn
        xDir
        xSw
        xInt1
        xInt2
        yPls
        yEn
        yDir
        ySw
        yInt1
        yInt2
    end
    
    methods
        
        function [] = print(this)
            % Utility method to print out the pins, in case we forget!
            fprintf("   Enable    Direction    Pulse    Terminal Switch  Interrupt 1  Interrupt 2\n");
            fprintf("X: %s        %s           %s       %s               %s           %s\n", this.xEn, this.xDir, this.xPls, this.xSw, this.xInt1, this.xInt2);
            fprintf("Y: %s        %s           %s       %s               %s           %s\n", this.yEn, this.yDir, this.yPls, this.ySw, this.yInt1, this.yInt2);
        end
        
    end
end

