% Test script for gantry, makes it move in an octagon and then return home.
% This is a nice example of how to use the gantry class in programmed mode.

% The most important thing to note is that everything happens inside the
% main while loop, which is timed so that each iteration takes a set amount
% of time. Rather than waiting for the gantry to stop moving, the loop
% starts the gantry moving to the next point, keeps looping, and each loop
% iteration it checks if the gantry has finished moving and if so, it
% starts it moving to the next point.

clear all;
a = arduino("COM5", "Mega2560", "Libraries", {"RotaryEncoder"});

% Create pin configuration object and assign pins
pins = gantryPins;
pins.xEn = "D6";
pins.xDir = "D8";
pins.xPls = "D10";
pins.xSw = "D12";
pins.xInt1 = "D21";
pins.xInt2 = "D20";
pins.yEn = "D7";
pins.yDir = "D9";
pins.yPls = "D11";
pins.ySw = "D13";
pins.yInt1 = "D19";
pins.yInt2 = "D18";

g = gantry(a, pins); % Initialise gantry
g.mode = gantryMode.PROGRAMMED; % Allow this script to control the updates

% This value is determined by the speed of the connection between MATLAB
% and the arduino (normally around 25ms, so I've chosen 50 to be safe)
updatePeriod = 0.05;

% Manually calibrate the gantry to set its limits (this also homes it)
g.calibrate;

% A list of points to visit, in order
pattern = [
    100, 200;
    100, 300;
    200, 400;
    300, 400;
    400, 300;
    400, 200;
    300, 100;
    200, 100;
    100, 200;
    0, 0;
] .* 0.5;

% Relative vector version
% pattern = [
%     100, 300;
%     100, 100;
%     100, 0;
%     100, -100;
%     0, -100;
%     -100, -100;
%     -100, 0;
%     -100, 100;
%     0, 100;
% ];

i = 1; % Pattern index

while true % Forever (until break statement)
    
    tic; % Start the timer
   
    % Let the gantry object update its current position and perform logic
    % (such as detecting when it has reached the destination or the limit
    % of its travel)
    g.update();
    
    if ~g.isMoving % If the gantry has finished moving (or hasn't started)
        
        % End the loop if the pattern is finished
        if i > length(pattern)
            break;
        end
        
        % Start the gantry moving towards the ith point in the pattern
        g.moveTo(pattern(i, 1), pattern(i, 2));
        
        i = i+1; % Move i to the next point in the pattern
        
    end
    
    % Sensing, grabber arm and other logic might go here
    
    % Each loop iteration must take 0.05s so wait for the remaining time
    pause(updatePeriod - toc);
    
end