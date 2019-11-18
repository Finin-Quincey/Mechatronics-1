% Plot Voltages over time
%Connecting the Arduino
clear
george =arduino("COM5","Mega2560");


Hello = HallSensor(george, "D8");

voltages= zeros(500,1);

H=plot(voltages);

while true
    
V = Hello.readVoltage();
pause (0.01);

voltages= [voltages(2:end);V];
    
H.YData= voltages;

end
