%%%%%%%%%%%%%%%%%%%%%%TREASURE HUNT%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%PREPARE THE HUNT%%%%%%%%%%%%%

%Setup the Arduino
clear all
george = arduino("COM5", "Mega2560", "Libraries", ["I2C", "SPI", "Servo", "RotaryEncoder", "BathUniversity/StepperMotorAddOn"]);

% Create pin configuration object and assign pins
pins = gantryPins;
pins.xEn = "D49";
pins.xDir = "D48";
pins.xPls = "D46";
pins.xSw = "D47";
pins.xInt1 = "D20";
pins.xInt2 = "D21";
pins.yEn = "D42";
pins.yDir = "D43";
pins.yPls = "D44";
pins.ySw = "D45";
pins.yInt1 = "D18";
pins.yInt2 = "D19";
g = gantry(george, pins); % Initialise gantry

sensor1 = HallSensor(george, "A0");
sensor2 = HallSensor(george, "A1");
sensor3 = HallSensor(george, "A2");
% arm= arm();
% gripper=gripper();

g.mode = gantryMode.PROGRAMMED; % Allow this script to control the updates
updatePeriod = 0.05;

%Initialise the Gantry position
g.calibrate;

%Wait until key presses - see function!!!
input('press to continue');
    
% %%%%INITIALISE the ARM & GRIPPER POSITIONS%%%%%
% 
% %%%%%%%%%%%%%%SCAN FOR TREASURES%%%%%%%%%%%%%

g.setSpeed(15); % Make it move slower!

% %ZigZagScan of the entire beach.
% %Outputs 3 matrices with signals detected from each sensor
[v1,v2,v3] = zigzagScan(george, g, sensor1, sensor2, sensor3);

% Combine the 3 signals into one long list
v = v3;%[v1; v2; v3];

% Assign columns to variables
x = v(:, 1);
y = v(:, 2);
z = v(:, 3);

% Offset data down by base voltage of hall sensor
z = z - 2.55;

% Take magnitude of values
z = abs(z);

%Interpolate the data

%Apply a threshold - only consider signals above that threshold
for i = 1:size(z, 1)
    for j= 1:size(z, 2)
        if z(i,j) < 0.2
            z(i,j) = 0;
        end
    end
end

% Clean the data - interpolate to get a more accurate data
[xq,yq] = meshgrid(1:2:length(x),1:2:length(y)); % increase the steps between each x-y values

G = griddata(x, y, z, xq, yq,'cubic'); %intropolated the data recorded according to these intropolated x-y values.

G(isnan(G)) = 0;

%%%%%%%%%%%%%% THE LOCATIONS OF THE TREASURES %%%%%%%%%%%%%%
%Determine the epicenters from data.

treasurePeaks = imregionalmax(G); % returns the binary image that identifies the regional maxima in matrix. .
[Xpeaks,Ypeaks]=find(treasurePeaks ==1);% returns the x-y coordinates of those peaks.

treasureCoord=[Xpeaks,Ypeaks]; %creates 2-columns matrix with x-y coordinates

%Classify from the furthest to closest 
treasureOrder = sortrows(treasureCoord,2,'descend');
%sorts A based on the columns specified in the vector column.
%in descending order

numberTreasures=length(treasureCoord); %the number of treasures is equal to the nbr of peaks found

%%%%%%%%%%%%%%%% COLLECTION OF CUPS, GO TO TREASURE & COVER IT %%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%% AND REPEAT UNTILL ALL TREASURES COVERED%%%%%%%%%%%%%%%%%%%%

% Let the gantry update itself, we don't need to do anything while it's moving
g.mode = gantryMode.MANUAL;
g.setSpeed(30);
g.home;

%2 stacks of cups located: 1. under home 2. just next to 1 in y direction

stack1XY = [0 0]; % Position of first stack
stackSpacing = [0, 80]; % Offset to get to next stack

nCups = 5; %number of cups per stack
% cupHeight=(38-7.5);% 24.5mm
% betweenCups=13; %in mm 
% maxHeight=(4*betweenCups)+cupgrabHeight; %topcup will be grabbed at%76.5
% heightDiff= 7.5*2; %14mm

cupHeights=[76.5 % topCup 1
            62.5 % Cup 2
            48.5 % Cup 3
            34.5 % Cup 4
            20.5]; %lastCup 5

for i = 1:numberTreasures % For each treasure location
    
    stackNumber = (i+1)/5; % 0 for i=1:5, 1 for i=6:10, etc.
    
    g.moveTo(stack1XY(1) + stackSpacing(1) * stackNumber, stack1XY(2) + stackSpacing(2) * stackNumber);
    height=cupHeight(i,1);
    arm.movetoheight(this,height,down); %lower the arm to top cup height.
    gripper.grab;
    height=highPos;
    arm.movetoheight(this,height,up);% higher to high pos
    
    g.moveTo(treasureOrder(i, 1), treasureOrder(i, 2));
    
    height=dropPos;
    arm.movetoheight(this,height,down);
    gripper.release;
    
    height=highPos;
    arm.movetoheight(this,height,down);
    
end

