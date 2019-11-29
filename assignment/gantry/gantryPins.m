classdef gantryPins < handle
    
    % GANTRYPINS Simple class that stores a set of gantry pins
    % Allows the gantry pins to be declared in a more readable fashion
    % whilst still requiring them to be initialised in the gantry
    % constructor. Also allows multiple pin configurations to be stored and
    % switched between without reinitialising the gantry.
    
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

