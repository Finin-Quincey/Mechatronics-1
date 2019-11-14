% LED Pulse Width Modulation
buttonPin = "D8";
ledPin = "D3";

refreshRate = 10; % Read rate in Hz
dutyCycle = 0.8;

% Setup
configurePin(george, buttonPin, "DigitalInput");
configurePin(george, ledPin, "PWM");

t = 0;

while true

    writePWMDutyCycle(george, ledPin, (sin(t/20) + 1)/2);
   
    t = t + 1;
    
    pause(0.01);
    
end
