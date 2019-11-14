% Controls the speed of a motor based on the position of a potentiometer

% Setup
motorPin = "D3";
potPin = "A0";

maxVoltage = 5;
refreshRate = 50;

timeScale = 200;

configurePin(george, motorPin, "PWM");
configurePin(george, potPin, "AnalogInput");

voltages = zeros(timeScale, 1);

h = plot(voltages);
xlim([0, timeScale]);
ylim([0, maxVoltage]);

t = 0;

while isvalid(h)

    voltage = readVoltage(george, potPin);
    
    voltages = [voltages(2:end); voltage];
    
    h.YData = voltages;
    
    speed = voltage/maxVoltage;
    
    writePWMDutyCycle(george, motorPin, speed);
   
    t = t + 1;
    
    pause(1/refreshRate);

end