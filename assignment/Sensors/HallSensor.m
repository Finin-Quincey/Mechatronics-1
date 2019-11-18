classdef HallSensor < handle
    %HallSensor is a device that is used to measure the magnitude of a magnetic field.
    %Its output voltage is directly proportional to the magnetic field strength through it.
    %They are responsible of detecting the magnetic field of the magnets.
  
    
    properties
        %Pins
        
    end
    
    methods
        function obj = untitled3(inputArg1,inputArg2)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

