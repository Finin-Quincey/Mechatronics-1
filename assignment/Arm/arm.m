classdef arm < handle
    %ARM controls the height of the gripper.
    %Programmed to be set in 3 different positions: low, high and drop cup.
    %Powered by a stepper motor.
    
    properties
        %Arduino
        a
        
        %Pins
        pulsePin %PWM 
        bluePin % DigitalOutput
        yellowPin % DigitalOutput
        pinkPin % DigitalOutput
        orangePin % DigitalOutput
        
        %Variable
        highPos= ;% setting up the nbr of steps required to get to this position
        lowPos=;
        dropPos=;
    end
    
    methods
        %Constructor
        function this = arm(a, pulsePin, bleuPin,yellowPin,pinkPin,orangePin)
            
            this.a=a;
            this.pulsePin = pulsePin;
            this.bluePin = bluePin;
            this.yellowPin = pinkPin;
            this.orangePin = orangePin;
            
            %Automatically configure the Analog Pin
            configurePin(this.a, this.pulsePin, "PWM");
            writePWMDutyCycle(this.a, this.pulsePin, 0.5);
            configurePin(this.a, this.bluePin, "DigitalOutput");
            configurePin(this.a, this.yellowPin, "DigitalOutput");
            configurePin(this.a, this.pinkPin, "DigitalOutput");
            configurePin(this.a, this.orangePin, "DigitalOutput");
            
            
        
        function [] = height(this,position,reverse)
            %HEIGHT inputs: nbr of steps to reach desired position
            % outputs:  rotation of motor 
            
       

  
  
        end
    end
end

