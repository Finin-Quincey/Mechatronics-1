%GANTRYMOVESENSORTEST Script to make the gantry move in a linear scanning pattern, with smallest
%step as possible, in order to sens the magnet and test its capabilities.
%Aim to move within a 10x10cm square,with magnet in the middle. 
%2 tests: one with the strong magnet in the center, one with the weak one.

%Setup the Arduino
clear
george =arduino("COM5","Mega2560");

%Setup of Gantry & Hall Sensor 
gantry = gantry(george, "D9", "D11", "D10", "D8", "D7", "D6", "D4");
sensor = HallSensor(george, "A8");

%Create initial matrix (1st test with 100x100 res.)
V= zeros(1,3);

%Initialise the Gantry position
gantry.home();

%for-loop to read data while moving the gantry

V1 = [];
for i = 1:20
    
    for i = 1:20
        
        %move forward for 5sec
        move = gantry.move(0,5);
        
        V1 = [gantry.pos,sensor.Read()]; %row vector
        
        V(end+1,:)=V1; %Always adding by the last row
    end
    move= gantry.move(1,0);
    
    for i=1:20
        
        move= gantry.move(0,-5);
        
        V1 = [gantry.pos,sensor.Read()]; %row vector
        
        V(end+1,:)=V1; %Always adding by the last row
        
    end
    move= gantry.move(1,0);
end
 
%scatter3(V(:,1),V(:,2),V(:,3))
