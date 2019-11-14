result = 0;

while true
    
    status = readDigitalPin(a, "D8");
    
    if result ~= status
        disp(status);
    end
    
    result = status;
    
    pause(0.1);
    
end