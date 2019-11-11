
configurePin(george,"D13","DigitalOutput");
configurePin(george,"D12","DigitalOutput");
configurePin(george,"D11","PWM");
configurePin(george,"A11","AnalogInput");

voltages= zeros(500,1);

H=plot(voltages);

while true
    
    V= readVoltage(george,"A11"); 
    pause (0.01); %implement the timer for better algorithms
    
    voltages= [voltages(2:end);V];%brackets are putting an array together
    
    H.YData= voltages;
    
end
