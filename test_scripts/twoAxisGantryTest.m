clear;

% Constants

PWM01 = "D9";
PWM02 = "D10";
PWM03 = "D11";

enableX = "D2";
directionX = "D3";
terminalSwitchX = "D4";

enableY = "D5";
directionY = "D6";
terminalSwitchY = "D7";

dutyCycle = 0.5; % Fraction of the 1/3x period

PWM01DC = 5/6 - 2/3 * dutyCycle;
PWM02DC = 1/2 + 2/3 * dutyCycle;
PWM03DC = 1/3 * dutyCycle;

% Arduino setup

a = arduino("COM6", "Uno");

configurePin(a, PWM01, "PWM");
configurePin(a, PWM02, "PWM");
configurePin(a, PWM03, "PWM");

configurePin(a, enableX, "DigitalOutput");
configurePin(a, directionX, "DigitalOutput");
configurePin(a, terminalSwitchX, "DigitalInput");

configurePin(a, enableY, "DigitalOutput");
configurePin(a, directionY, "DigitalOutput");
configurePin(a, terminalSwitchY, "DigitalInput");

% Set up fancy PWM stuff

writePWMDutyCycle(a, PWM01, PWM01DC);
writePWMDutyCycle(a, PWM02, PWM02DC);
writePWMDutyCycle(a, PWM03, PWM03DC );

% Movement

writeDigitalPin(a, enableX, 0);
writeDigitalPin(a, directionX, 0);

writeDigitalPin(a, enableY, 0);
writeDigitalPin(a, directionY, 1);

while readDigitalPin(a, terminalSwitchX)
    pause(0.01);
end

writeDigitalPin(a, enableX, 1);
writeDigitalPin(a, enableY, 1);