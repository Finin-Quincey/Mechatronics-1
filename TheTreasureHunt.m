%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TREASURE HUNT %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% PREPARE THE HUNT %%

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
g.setSpeed(15);
% Initialise the gantry position tracking and limits
g.calibrate;

% Wait until key presses - see function!!!
input('press to continue');
    
%% SCAN FOR TREASURES %%

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

%For test purposes, uncomment this section for visualise the results
% scatter3(v1(:, 2), v1(:, 1), v1(:, 3), 'k');
% hold on;
% scatter3(v2(:, 2), v2(:, 1), v2(:, 3), 'b');
% scatter3(v3(:, 2), v3(:, 1), v3(:, 3), 'o');

input('press to continue');

%% PROCESS THE DATA %%
% 1. Offset data down by base voltage of hall sensor
z = z - 2.5;

% 2. Clean the data - interpolate to get a more accurate data
[xq, yq] = meshgrid(1:5:length(x), 1:5:length(y)); % 5mm steps between each x-y value

G = griddata(x, y, z, xq, yq, 'cubic'); % Interpolate the data recorded according to these finer x-y values

% 3. Take magnitude of values
G = abs(G);

% 4. Apply a threshold - only consider signals above that threshold
% This cuts out all the noisy background data, we don't want to detect
% hundreds of tiny peaks!
G(G < 0.03) = 0;

G(isnan(G)) = 0; %This converts all NaN values to 0.

treasureCoord = [];
r=35; %radius of cercle corresponding to cup diameter

G1 = G;

%5. Loop that finds the highest peak of the matrix, stores its coordinates, then deleted
%all data within a radius from this peak. This is because no magnets will be
%located this close to each other, as a cup will be covering this area.
%Loop keeps repeating this process until all points higher that a given value are
%deleted. 
while max(G1, [], 'all') > 0.03
    
    % Find max value over all elements.
    maxPoint = max(G1,[],'all'); 
    
    % Returns the x-y coordinates of that peak
    [Xindex, Yindex] = find(G1 == maxPoint);  %returns a vector containing the linear indices of each nonzero element in array G.
    
    % Convert those indices in the x-y position
    Xpeak = xq(1, Xindex);
    Ypeak = yq(Yindex, 1);
    
    % Store those coordinates into a 2-columns matrix
    treasureCoord(end+1, :) = [Ypeak, Xpeak]; 
    
    % Erase values that are within a radius from max point
    G1 = (bwdist(G1 == maxPoint) >= r) .* G1; 

    %For testing purposes, uncomment this section to visualise the results
    %at each loop
%     h = figure;
%     surf(G1);
%     hold on
%     scatter3(treasureCoord(:, 1), treasureCoord(:, 2), ones(size(treasureCoord, 1), 1) * 10, 'ro');
%     
%    close(h);
    
end


% Classify from the furthest to closest 
treasureOrder = sortrows(treasureCoord, 2, 'descend');
% Sorts coords based on the columns specified in the vector column
% In descending order

% The number of treasures is equal to the nbr of peaks found
numberTreasures = length(treasureCoord);

%% COLLECT CUPS, GO TO TREASURES & COVER THEM %%

% Let the gantry update itself from here on, we don't need to do anything while it's moving
g.mode = gantryMode.MANUAL;
g.setSpeed(30); % Increase the speed again for this bit
g.home; % Re-home just in case

% 2 stacks of cups located: 1. under home 2. just next to 1 in y direction

stack1XY = [0, g.limits(2)]; % Position of first stack
stackSpacing = [80, 0]; % Offset to get to next stack

nCups = 5; % Number of cups per stack

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

