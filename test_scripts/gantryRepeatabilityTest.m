decelTime = 0.03;
dc = 0.05;

h = msgbox("Repeatability test running...");

while isvalid(h)
    tic;
    writePWMDutyCycle(a, "D3", dc);
    writeDigitalPin(a, "D5", 0);
    writeDigitalPin(a, "D4", 1);
    pause(3-toc);
    tic;
    writePWMDutyCycle(a, "D3", 1);
    pause(decelTime);
    writeDigitalPin(a, "D5", 1);
    pause(0.5-toc);
    tic;
    writePWMDutyCycle(a, "D3", dc);
    writeDigitalPin(a, "D5", 0);
    writeDigitalPin(a, "D4", 0);
    pause(3-toc);
    tic;
    writePWMDutyCycle(a, "D3", 1);
    pause(decelTime);
    writeDigitalPin(a, "D5", 1);
    pause(0.5-toc);
end