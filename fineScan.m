function [v1.fine,v2b.fine,v3.fine] = fineScan(a, this.gantry,this.sensor1,this.sensor2,this.sensor3,XstartPos, YstartPos,XendPos, YendPos)
%FINESCAN makes the gantry move to given point and scan an area
%%%INPUTS%%
%A, THIS.GANTRY,THIS.SENSOR1,THIS.SENSOR2,THIS.SENSOR3 - objects used in
%the function
%%XSTARTPOS & YSTARTPOS give the coordinates of the starting position.
%XENDPO & YENDPOS give the coordinate of the end position.

%Create initial matrix
v1b= zeros(1,3);
v2b= zeros(1,3);
v3b= zeros(1,3);

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
        
        v1b(end+1,:)=V1;
        v2b(end+1,:)=V2;
        v3b(end+1,:)=V3;
     
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



%%%CALIBRATE RECORDED DATA BY IMPLEMENTING OFFSETS%%%

%%Initialise relative position to each other%%
%Assume the triangular shaped display is right below the gantry
%     S3

%    0,0

%S1          S2

d=60.6; %in mm

%Sensor 1

x1offset = -(d/2) ;
y1offset = -(root((d^2)-((d/2)^2))/2;

x2offset = (d/2);
y2offset = -(root((d^2)-((d/2)^2))/2;

x3offset= 0 ;
y3offset=(root((d^2)-((d/2)^2))/2;


%Input the offset in the recorded data
%This enables to have the sensing reading according to the absolute
%position of the gantry g.pos

v1b.fine=[x1+x1offset y1+y1offset z1]; %gives us [x y z1]
v2b.fine=[x2+x2offset y2+y2offset z2]; %gives us [x y z2]
v3b.fine=[x3+x3offset y3+y3offset z3]; %gives us [x y z3]


end

