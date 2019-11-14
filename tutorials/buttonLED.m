% Simple script to make a button toggle an LED on/off
buttonPin = "D8";
ledPin = "D13";

status = 0;
led = 0;
refreshRate = 10; % Read rate in Hz

% Setup
configurePin(george, buttonPin, "DigitalInput");
configurePin(george, ledPin, "DigitalOutput");

while true
    
    % Read button status every 0.1 seconds until it's off
    while status == 1
        status = readDigitalPin(george, buttonPin);
        pause(1/refreshRate);
    end
    
    writeDigitalPin(george, "D13", ~led); % Toggle LED state
    led = ~led; % Store new LED state in the led variable
    
    % Read button status every 0.1 seconds until it's on
    while status == 0
        status = readDigitalPin(george, buttonPin);
        pause(1/refreshRate);
    end
    
end