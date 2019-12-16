% Test script for the low-pass filter; sweeps through duty cycles from 0 to
% 1 and records the plots them against the voltage output from the filter,
% recorded via pin A0.

% Setup
xPulsePin = "D3";
voltageInputPin = "A0";

configurePin(a, xPulsePin, "PWM");
configurePin(a, voltageInputPin, "AnalogInput");

dcs = 0:0.01:1;
v = zeros(1, length(dcs));
n = 1;

% Loop through PWM duty cycles 0-1
for dc = dcs
    writePWMDutyCycle(a, xPulsePin, dc);
    v(n) = readVoltage(a, voltageInputPin); % Record voltage output
    n = n+1;
    pause(0.2); % Pause to allow the filter to settle
end

% Plot the results
scatter(dcs, v, 'kx');
xlabel("Input PWM Duty Cycle");
ylabel("Low-pass Output Voltage (V)");
grid on;