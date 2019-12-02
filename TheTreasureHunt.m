%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TREASURE HUNT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PREPARE THE HUNT! %%

% Setup the Arduino
clear all; % Clear all is necessary due to a weird bug in the RotaryEncoder library
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

m = arm(george, "D3");
gripper = gripper(george, "D4");

g.mode = gantryMode.PROGRAMMED; % Allow this script to control the updates
% Limited by the speed of the connection between MATLAB and the Arduino
updatePeriod = 0.05; % Poll the sensors + gantry at 20Hz

% Initialise the gantry position tracking and limits
g.calibrate;

% Wait until key presses - see function!!!
input('press to continue');
    
%% SCAN FOR TREASURES! %%

g.setSpeed(15); % Make it move slower for the scanning, it's more accurate
m.down; % Scan at lowest arm position

% ZigZagScan of the entire beach.
% Outputs 3 matrices with signals detected from each sensor
[v1, v2, v3] = zigzagScan(g, sensor1, sensor2, sensor3);

% Combine the 3 signals into one long list
v = [v1; v2; v3];

% Assign columns to variables
x = v(:, 1);
y = v(:, 2);
z = v(:, 3);


%% PROCESS THE DATA! %%
% 1. Offset data down by base voltage of hall sensor
z = z - 2.55;

% 2. Clean the data - interpolate to get a more accurate data
[xq, yq] = meshgrid(1:5:length(x), 1:5:length(y)); % 5mm steps between each x-y value

G = griddata(x, y, z, xq, yq,'cubic'); % Interpolate the data recorded according to these finer x-y values

% 3. Take magnitude of values
z = abs(z);

% 4. Apply a threshold - only consider signals above that threshold
% This cuts out all the noisy background data, we don't want to detect
% hundreds of tiny peaks!
for i = 1:size(z, 1)
    for j= 1:size(z, 2)
        if z(i,j) < 0.05
            z(i,j) = 0;
        end
    end
end

G(isnan(G)) = 0; %This converts all NaN values to 0.

treasureCoord = [];
r=35; %radius of cercle corresponding to cup diameter
theta = 0 : 0.01 : 2*pi;

% Determine the epicenters from data
while G > 1
    % Find max value over all elements.
    maxPoint = max(G,[],'all'); % finds the maximum over all elements of G.
    
    % Returns the x-y coordinates of that peak
    [Xindex Yindex] = find(G == maxPoint);  %returns a vector containing the linear indices of each nonzero element in array G.
    
    %convert those indices in the x-y position
    Xpeak=xq(Xindex);
    Ypeak=yq(Yindex);
    
    % Store those coordinates into a 2-columns matrix
    treasureCoord(end+1,:)=[Xpeak, Ypeak];
    
    %Erase values that are within a radius from max point
    
    
    u=find(xq >(Xpeak-r) && xq < (Xpeak+r)); 
    v=find(yq <(Ypeak-r) && yq < (Ypeak+r));
    
    G(u,v)= (hypot(Xpeak-xq(u))>=r)*G(u,v); %this would cut reduce the initia scquare into a circle by cutting off edges

end

MAX=X(1,1);
for i=1:3
for j=1:3
if MAX<= X(i,j);
MAX=X(i,j);


treasurePeaks = imregionalmax(G); % Returns the binary image that identifies the regional maxima in matrix
[Xpeaks, Ypeaks] = find(treasurePeaks == 1); % Returns the x-y coordinates of those peaks

treasureCoord = [Xpeaks, Ypeaks]; % Creates 2-columns matrix with x-y coordinates



% Classify from the furthest to closest 
treasureOrder = sortrows(treasureCoord, 2, 'descend');
% Sorts coords based on the columns specified in the vector column
% In descending order

% The number of treasures is equal to the nbr of peaks found
numberTreasures = length(treasureCoord);

%% COLLECT CUPS, GO TO TREASURES & COVER THEM! %%

% Let the gantry update itself from here on, we don't need to do anything while it's moving
g.mode = gantryMode.MANUAL;
g.setSpeed(30); % Increase the speed again for this bit
g.home; % Re-home just in case

% 2 stacks of cups located: 1. under home 2. just next to 1 in y direction

stack1XY = [0, g.limits(2)]; % Position of first stack
stackSpacing = [80, 0]; % Offset to get to next stack

nCups = 5; % Number of cups per stack

% This is now done in the arm class
% cupHeight=(38-7.5);% 24.5mm
% betweenCups=13; %in mm 
% maxHeight=(4*betweenCups)+cupgrabHeight; %topcup will be grabbed at%76.5
% heightDiff= 7.5*2; %14mm

% cupHeights=[76.5 % topCup 1
%             62.5 % Cup 2
%             48.5 % Cup 3
%             34.5 % Cup 4
%             20.5]; %lastCup 5

for i = 1:numberTreasures % For each treasure location
    
    stackNumber = (i+1)/5; % 0 for i=1:5, 1 for i=6:10, etc.
    cupNumber = 5 - mod((i+1), 5); % Position of cup in the stack
    
    g.moveTo(stack1XY(1) + stackSpacing(1) * stackNumber, stack1XY(2) + stackSpacing(2) * stackNumber);

    m.pickupHeight(cupNumber); % Lower the arm to top cup height
    gripper.grab;
    
    m.up; % Raise to high pos
    
    g.moveTo(treasureOrder(i, 1), treasureOrder(i, 2));
    
    m.pickupHeight(this, 4); % Drop at second-lowest cup height
    gripper.release;
    
    m.up;
    
end

g.home; % Return home to finish

