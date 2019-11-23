%GANTRYMOVESENSORTEST Script to make the gantry move in a linear scanning pattern, with smallest
%step as possible, in order to sens the magnet and test its capabilities.
%Aim to move within a 10x10cm square,with magnet in the middle. 
%2 tests: one with the strong magnet in the center, one with the weak one.

%Setup the Arduino
clear
george =arduino("COM5","Mega2560");

%Setup of Gantry & Hall Sensor 
g = gantry(george, "D9", "D11", "D10", "D8", "D7", "D6", "D4");
sensor1 = HallSensor(george, "A2");
sensor2 = HallSensor(george, "A1");
sensor3 = HallSensor(george, "A0");

g.mode = gantryMode.PROGRAMMED; % Allow this script to control the updates
updatePeriod = 0.05;

%Create initial matrix (1st test with 100x100 res.)
Va= zeros(1,3);
Vb= zeros(1,3);
Vc= zeros(1,3);


%Initialise the Gantry position
g.calibrate;

%for-loop to read data while moving the gantry

x = 20 + floor(((1:40)-1)/2)*1; % 50, 50, 55, 55, 60, 60, ....
y = 10 + (mod(1:40, 4) < 2) * 40; % 100, 40, 40, 100, 100, 40....

pattern = [x',y'];

V1=[];
V2=[];
V3=[];

i=1;

while true% Forever (until break statement)
    
    tic; % Start the timer
    
    % Let the gantry object update its current position and perform logic
    % (such as detecting when it has reached the destination or the limit
    % of its travel)
     g.update();
     
     
        V1 = [g.pos,sensor1.Read()];
        V2 = [g.pos,sensor2.Read()]; 
        V3 = [g.pos,sensor3.Read()]; 
        
        Va(end+1,:)=V1;
        Vb(end+1,:)=V2;
        Vc(end+1,:)=V3;
     
     if ~g.isMoving % If the gantry has finished moving (or hasn't started)
        
        % End the loop if the pattern is finished
        if i > length(pattern)
            break;
        end
        
        % Start the gantry moving towards the ith point in the pattern
        g.moveTo(pattern(i, 1), pattern(i, 2));
        
        i = i+1; % Move i to the next point in the pattern
        
     end
end


