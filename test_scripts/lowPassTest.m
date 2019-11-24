xPulsePin = "D3";
voltageInputPin = "A0";

configurePin(a, xPulsePin, "PWM");
configurePin(a, voltageInputPin, "AnalogInput");

dcs = 0:0.01:1;
v = zeros(1, length(dcs));
n = 1;

for dc = dcs
    writePWMDutyCycle(a, xPulsePin, dc);
    v(n) = readVoltage(a, voltageInputPin);
    n = n+1;
    pause(0.2);
end

scatter(dcs, v, 'kx');
xlabel("Input PWM Duty Cycle");
ylabel("Low-pass Output Voltage (V)");
grid on;