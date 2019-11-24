% Oscillator diagnostics
% Uses analog pins to display a 'scope' in MATLAB to examine the oscillator
% behaviour. Useful for tuning components to achieve the desired frequency
% range.

xPulsePin = "D3";
voltageReadPin = "A0";
oscillatorReadPin = "A1";

configurePin(a, xPulsePin, "PWM");
configurePin(a, voltageReadPin, "AnalogInput");
configurePin(a, oscillatorReadPin, "AnalogInput");

writePWMDutyCycle(a, xPulsePin, 0.1);

timescale = 5; % seconds
freq = 20; % Hz

t = (1:timescale*freq) / freq;
v = zeros(1, timescale*freq);
s = zeros(1, timescale*freq);

h = plot(t, v);
hold on;
g = plot(t, s);

while isvalid(h) && isvalid(g)
    v = [v(2:end), readVoltage(a, voltageReadPin)];
    h.YData = v;
    s = [s(2:end), readVoltage(a, oscillatorReadPin)];
    g.YData = s;
    pause(1/freq);
end