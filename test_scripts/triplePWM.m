clear;

refPin = "D3";

inverted = "D9";
signalA = "D10";
signalB = "D11";

dutyCycle = 0.5; % Fraction of the 1/3x period

invertedDC = 5/6 - 2/3 * dutyCycle;
signalADC = 1/2 + 2/3 * dutyCycle;
signalBDC = 1/3 * dutyCycle;

a = arduino("COM6", "Uno");

configurePin(a, refPin, "PWM");
configurePin(a, inverted, "PWM");
configurePin(a, signalA, "PWM");
configurePin(a, signalB, "PWM");

writePWMDutyCycle(a, refPin, 0.5);
writePWMDutyCycle(a, inverted, invertedDC);
writePWMDutyCycle(a, signalA, signalADC);
writePWMDutyCycle(a, signalB, signalBDC );

% tic
% writePWMDutyCycle(a, invertedA, 0.67);
% while toc < 1/490
%     pause(0.0001);
% end
% tic
% writePWMDutyCycle(a, invertedB, 0.33);
% while toc < 1/490
%     pause(0.0001);
% end
% writePWMDutyCycle(a, signalA, 0.67);