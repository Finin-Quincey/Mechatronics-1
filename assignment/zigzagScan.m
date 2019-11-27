function [v1Update,v2Update,v3Update] = zigzagScan(a, this.gantry,this.sensor1,this.sensor2,this.sensor3)
%ZIGZAGMove makes the gantry move following a given pattern, 
% records the magnetic field from the scanned area from the 3 Sensors &
% applies the offsets of the sensor relative to the absolute gantry
% position g.pos to obtain the voltages recorded from each sensor for given
% positions.

%%%%INPUTS:%%%%
%A, THIS.GANTRY,THIS.SENSOR1,THIS.SENSOR2,THIS.SENSOR3 - objects used in
%the function (Their setup not included)

%%%%OUTPUTS%%%
%3 matrices: one for each sensors
% each matrix in the format:[g.posX,g.posY,voltages];
% Offset considered to get aboslute position for each voltages reading of
%each sensor

%Initialise the parameters
Xarea=500; %in mm
Yarea=500; %in mm
res= 8.3; %in mm 

%Determine the pattern by a series of coordinates
pattern=[0 0;
    0 8.3
    8.3 0
    16.6 0
    0 16.6
    0 24.9
    24.9 0
    33.2 0
    0 33.2
    0 41.5
    41.5 0
    49.8 0
    0 49.8
    8.3 49.8
    49.8 8.3
    49.8 16.6
    16.6 49.8
    24.9 49.8
    49.8 24.4
    49.8 33.2
    33.2 49.8
    41.5 49.8
    49.8 41.5
    49.8 49.8
    ];

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
        
        % Start the gantry moving towards the ith point in the pattern
        g.moveTo(pattern(i, 1), pattern(i, 2));
        
        i = i+1; % Move i to the next point in the pattern
        
    end
            

%%%CALIBRATE RECORDED DATA BY IMPLEMENTING OFFSETS%%%

%%Initialise relative position to each other%%
%Sensors in a triangular configuration:
%      S3

%     0,0

%S1          S2

d=60.6; %the distance between sensors in mm 

%Sensors offsets
x1offset = -(d/2) ;
y1offset = -(root((d^2)-((d/2)^2))/2;

x2offset = (d/2);
y2offset = -(root((d^2)-((d/2)^2))/2;

x3offset= 0 ;
y3offset=(root((d^2)-((d/2)^2))/2;


%Apply the offsets
%This enables to have the sensing reading according to the absolute
%position of the gantry g.pos.

v1Update=[x1a+x1offset y1a+y1offset z1]; %gives us [x y z1]
v2Update=[x2a+x2offset y2a+y2offset z2]; %gives us [x y z2]
v3Update=[x3a+x3offset y3a+y3offset z3]; %gives us [x y z3]

end
end








