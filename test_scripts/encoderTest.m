% Oh my gosh it actually works

%h = msgbox("Encoder test running...");

freq = zeros(1, 100);

h = plot(freq);

count = 0;

clear encoder;
encoder = rotaryEncoder(a, "D18", "D19");

resetCount(encoder);

tic;

while isvalid(h)
    c = readCount(encoder);
    %disp(c);
%     if c > count
%         writeDigitalPin(a, "D13", 1);
%     else
%         writeDigitalPin(a, "D13", 0);
%     end
    freq = [freq(2:end), 0.25 * (c - count)/toc];
    tic;
    h.YData = freq;
    count = c;
    pause(0.25);
end