clear;

% Constants

refPin = "D3";

inverted = "D9";
signalA = "D10";
signalB = "D11";

enablePin = "D2";
directionPin = "D4";
terminalSwitchPin = "D7";

dutyCycle = 0.5; % Fraction of the 1/3x period

invertedDC = 5/6 - 2/3 * dutyCycle;
signalADC = 1/2 + 2/3 * dutyCycle;
signalBDC = 1/3 * dutyCycle;

% Arduino setup

a = arduino("COM6", "Uno");

configurePin(a, refPin, "PWM");
configurePin(a, inverted, "PWM");
configurePin(a, signalA, "PWM");
configurePin(a, signalB, "PWM");

configurePin(a, enablePin, "DigitalOutput");
configurePin(a, directionPin, "DigitalOutput");
configurePin(a, terminalSwitchPin, "DigitalInput");

% Set up fancy PWM stuff

writePWMDutyCycle(a, refPin, 0.5);
writePWMDutyCycle(a, inverted, invertedDC);
writePWMDutyCycle(a, signalA, signalADC);
writePWMDutyCycle(a, signalB, signalBDC );

% Movement

writeDigitalPin(a, enablePin, 0);
writeDigitalPin(a, directionPin, 0);

while readDigitalPin(a, terminalSwitchPin)
    pause(0.01);
end

writeDigitalPin(a, enablePin, 1);

pause(1);

writeDigitalPin(a, enablePin, 0);
writeDigitalPin(a, directionPin, 1);

pause(10);

writeDigitalPin(a, enablePin, 1);

pause(1);

writeDigitalPin(a, enablePin, 0);
writeDigitalPin(a, directionPin, 0);

pause(10);

writeDigitalPin(a, enablePin, 1);