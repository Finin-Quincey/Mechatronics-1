classdef arm < handle
    %ARM controls the height of the gripper.
    %Programmed to be set in 3 different positions: low, high and drop cup.
    %Powered by a stepper motor.
    
    properties
        %Arduino
        a
        
        pulsePin %PWM 
        bluePin % DigitalOutput
        yellowPin % DigitalOutput
        pinkPin % DigitalOutput
        orangePin % DigitalOutput
        
        %Variable
%         highPos= ;% setting up the nbr of steps required to get to this position
%         lowPos=;
%         dropPos=;
%         cup5=; %height at which the top cup of stack is grabbed
%         lowerCup=;%height to be lowered to grab the lowercup.
        
        pins={d1};
    end
    
    methods
        %Constructor
        function this = arm(a, pulsePin, bluePin,yellowPin,pinkPin,orangePin)
            
            this.a=a;
            this.pulsePin = pulsePin;
            this.bluePin = bluePin;
            this.yellowPin = yellowPin;
            this.pinkPin = pinkPin;
            this.orangePin = orangePin;
            
            %Automatically configure the Analog Pin
            configurePin(this.a, this.pulsePin, "PWM");
            writePWMDutyCycle(this.a, this.pulsePin, 0.5);
            configurePin(this.a, this.bluePin, "DigitalOutput");
            configurePin(this.a, this.yellowPin, "DigitalOutput");
            configurePin(this.a, this.pinkPin, "DigitalOutput");
            configurePin(this.a, this.orangePin, "DigitalOutput");
            
%             function [] = printPins(this)
%             % Utility method to print out the pins, in case we forget!
%             fprintf("Arm control pins:\n");
%             this.pins.print();
%             
            function [] = movetoheight(this,previousPos,newPos,UPorDown,pins)
                %HEIGHT inputs: nbr of steps to reach desired position
                % outputs:  rotation of motor
                
                %set REVERSE is going UP
                up=reverse;
                down=0;
                
              %%%function [] = movetoheight(this,height,reverse,pins)   
              %add formula that converts that heigth into n-steps!!!

                n= mod(previousPos,newPos); %determine the nbr of steps to be done to obtain final position, considering the previous position.
            
                switchMatrix = [
                    1, 0, 1, 0;     %Step 1
                    0, 1, 1, 0;     %Step 2
                    0, 1, 0, 1;     %Step 3
                    1, 0, 0, 1      %Step 4
                    ];
                
                nRows = length(switchMatrix); 
                
                if reverse
                    d = -1; %CCW
                else
                    d = 1;  %CW
                end
                for i = 1:n
                    
                    currentRow = switchMatrix(mod(d*i, nRows) + 1, :);
                    prevRow = switchMatrix(mod(d*(i-1), nRows) + 1, :);
                    
                    for j = 1:4
                        if currentRow(j) ~= prevRow(j)
                            writeDigitalPin(this.a, pins{j}, currentRow(j));
                        end           
                    end
                    

        end
    end
end

