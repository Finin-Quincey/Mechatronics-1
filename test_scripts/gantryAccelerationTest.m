xPulsePin = "D3";
xDirectionPin = "D4";

configurePin(a, xPulsePin, "PWM");
configurePin(a, xDirectionPin, "DigitalOutput");

t = 1;

minDC = 0.1;
maxDC = 0.76;

while true

    writeDigitalPin(a, xDirectionPin, 1);
    
    for dc = 0.9 - (0.1:0.05:0.8)
        writePWMDutyCycle(a, xPulsePin, dc);
        pause(0.1);
    end
    
    pause(2);
    
    for dc = 0.1:0.05:0.8
        writePWMDutyCycle(a, xPulsePin, dc);
        pause(0.1);
    end

    writePWMDutyCycle(a, xPulsePin, 1);
    writeDigitalPin(a, xDirectionPin, 0);
    
    for dc = 0.9 - (0.1:0.05:0.8) 
        writePWMDutyCycle(a, xPulsePin, dc);
        pause(0.1);
    end
    
    pause(2);
    
    for dc = 0.1:0.05:0.8
        writePWMDutyCycle(a, xPulsePin, dc);
        pause(0.1);
    end

    writePWMDutyCycle(a, xPulsePin, 1);

end