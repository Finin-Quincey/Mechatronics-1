% Plot Voltages over time
%Connecting the Arduino
clear
george =arduino("COM5","Mega2560");

Hello = HallSensor(george, "A1");

voltages= zeros(500,1);

H=plot(voltages);

while true
    
V = Hello.Read();
pause (0.01);

voltages= [voltages(2:end);V];
    
H.YData= voltages;

end
