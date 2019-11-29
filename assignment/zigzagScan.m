function [v1Update,v2Update,v3Update] = zigzagScan(a, g, sensor1, sensor2, sensor3)
%ZIGZAGMove makes the gantry move following a given pattern, 
% records the magnetic field from the scanned area from the 3 Sensors &
% applies the offsets of the sensor relative to the absolute gantry
% position g.pos to obtain the voltages recorded from each sensor for given
% positions.

%%%%INPUTS:%%%%
%A, THIS.GANTRY,THIS.SENSOR1,THIS.SENSOR2,THIS.SENSOR3 - objects used in
%the function (Their setup not included)

%%%%OUTPUTS%%%\\
%3 matrices: one for each sensors
% each matrix in the format:[g.posX,g.posY,voltages];
% Offset considered to get aboslute position for each voltages reading of
%each sensor

%Initialise the parameters
Xarea=500; %in mm
Yarea=500; %in mm
res= 8.3; %in mm 

%Determine the pattern by a series of coordinates
% pattern=[0 0;
%     0 8.3;
%     8.3 0;
%     16.6 0;
%     0 16.6;
%     0 24.9;
%     24.9 0;
%     33.2 0;
%     0 33.2;
%     0 41.5;
%     41.5 0;
%     49.8 0;
%     0 49.8;
%     8.3 49.8;
%     49.8 8.3;
%     49.8 16.6;
%     16.6 49.8;
%     24.9 49.8;
%     49.8 24.4;
%     49.8 33.2;
%     33.2 49.8;
%     41.5 49.8;
%     49.8 41.5;
%     49.8 49.8;
%     ];

y = 

%pattern = generateZigzag(100, min(g.limits));

%%%MOVE FOLLOWING THE PATTERN WHILE READING VOLTAGES%%%

%Create initial matrices
v1= zeros(1,3);
v2= zeros(1,3);
v3= zeros(1,3);

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
    
    V1 = [g.pos,sensor1.Read()]; %Sensor recorded voltage relative to gantry position 
    V2 = [g.pos,sensor2.Read()];
    V3 = [g.pos,sensor3.Read()];
    
    v1(end+1,:)=V1; %Insert the voltage for given position to the matrix
    v2(end+1,:)=V2;
    v3(end+1,:)=V3;
    
    if ~g.isMoving % If the gantry has finished moving (or hasn't started)
        
        % End the loop if the pattern is finished
        if i > length(pattern)
            break;
        end
        
        pause(0.25); % Brief pause to allow the gantry to change direction more smoothly
        
        % Start the gantry moving towards the ith point in the pattern
        g.moveTo(pattern(i, 1), pattern(i, 2));
        
        i = i+1; % Move i to the next point in the pattern
        
    end
end       

%%%CALIBRATE RECORDED DATA BY IMPLEMENTING OFFSETS%%%

%%Initialise relative position to each other%%
%Sensors in a triangular configuration:
% S3

%    0,0   S2

% S1

d=50.6; %the distance between sensors in mm 

% Triangle calcs
a = 1/3 * sqrt(0.75) * d;
b = 2/3 * sqrt(0.75) * d;
c = d/2;

%Sensors offsets
x1offset = -c;
y1offset = -a;

x2offset = b;
y2offset = 0;

x3offset = c;
y3offset = -a;


%Apply the offsets
%This enables to have the sensing reading according to the absolute
%position of the gantry g.pos.

v1Update=[v1(:, 1)+x1offset v1(:, 2)+y1offset v1(:, 3)]; %gives us [x y z1]
v2Update=[v2(:, 1)+x2offset v2(:, 2)+y2offset v2(:, 3)]; %gives us [x y z2]
v3Update=[v3(:, 1)+x3offset v3(:, 2)+y3offset v3(:, 3)]; %gives us [x y z3]

end








