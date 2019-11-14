function [] = moveStepper(a, n, reverse, pins)

switchMatrix = [
    1, 0, 1, 0;
    0, 1, 1, 0;
    0, 1, 0, 1;
    1, 0, 0, 1
];

nRows = length(switchMatrix);

if reverse
    d = -1;
else
    d = 1;
end

for i = 1:n
    
    currentRow = switchMatrix(mod(d*i, nRows) + 1, :);
    prevRow = switchMatrix(mod(d*(i-1), nRows) + 1, :);
    
    for j = 1:4
        if currentRow(j) ~= prevRow(j)
            writeDigitalPin(a, pins{j}, currentRow(j));
        end
    end
    
    pause(0.02);

end