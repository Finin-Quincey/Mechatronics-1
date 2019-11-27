xPulsePin = "D3";
yPulsePin = "D9";

configurePin(a, xPulsePin, "PWM");
configurePin(a, yPulsePin, "PWM");

t = 1;

minDC = 0.1;
maxDC = 1;

while true
    writePWMDutyCycle(a, xPulsePin, (sin(t/20)+1)/2 * (maxDC-minDC) + minDC);
    writePWMDutyCycle(a, yPulsePin, (cos(t/20)+1)/2 * (maxDC-minDC) + minDC);
    t = t+1;
end