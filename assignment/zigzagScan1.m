function [v1.Update,v2.Update,v3.Update] = zigzagScan(a, this.gantry,this.sensor1,this.sensor2,this.sensor3,XstartPos, YstartPos, Xarea,Yarea,res, direction)
%ZIGZAGMove makes the gantry move following a given pattern.
%%%%INPUTS:%%%%
%A, THIS.GANTRY,THIS.SENSOR1,THIS.SENSOR2,THIS.SENSOR3 - objects used in
%the function
%XSTARTPOS & YSTARTPOS gives the coordinates of the starting position.
%XAREA & YAREA give the X-Y boundaries of the area to be scanned
%RES how refined the pattern should be executed.
%DIRECTION: Straight or Reverse.
        %Straight: go in positive x-y direction
        %Reverse: go in negative x-ydirection
%%%%OUTPUTS%%%
%3 matrices: one for each sensors
%matrices=[g.posX,g.posY,voltages];
%Offset considered to get aboslute position for each voltages reading of
%each sensor


%1st full scan
%Xarea=500; in mm
%Yarea=500; in mm
%res= 27; in mmm

%2nd scan
%Xarea=600; in mm
%Yarea=600; in mm
%res= 1; in mmm

% %Input the displacements
% i=0;
% for i= 0:12 %until halfway
%   
% y=0;
% x=0;
% if mod(i,4)<=1
%     
%     %points in y-axis 
%     
%     x(i)=0;
%     y(i)=y+i*res;
% else 
%     
%     %point in x-axis
%     x(i)=x+i*res;
% %     y(i)=0;
% 
% end
% %by this the gantry is at top-left corner, x= 49.8 to be exact!
% 
% yb=0;
% xb=50;
% 
% for i= 7:6
% if mod(i,4)<=1
%     
%     %points in x-axis 
%     xb(i)=0;
%     yb(i)=xb-i*res;
%    
% else 
%  %y-axis
%     xb(i)=;
%     yb(i)=;


%Assumed gantry is all setted up

1. Make the gantry move to start position
2. Make the gantry move in the pattern, considering resolution, direction and area boundries
3. While gantry moving, Sensors read the voltages
4. out

%%%MOVE TO STARTING POSITION%%%

g.moveTo(XstartPos,YstartPos);
%verification its as destination, when it is it can start moving floowing
%the pattern
% if this.destination = [XstartPos,YstartPos]; 

%%%MOVE FOLLOWING THE PATTERN WHILE READING VOLTAGES%%%

%Create initial matrix
v1= zeros(1,3);
v2= zeros(1,3);
v3= zeros(1,3);

V1=[];
V2=[];
V3=[];

i=1;
  
if direction==Straight
    
    while true% Forever (until break statement)
        
        tic; % Start the timer
        
        % Let the gantry object update its current position and perform logic
        % (such as detecting when it has reached the destination or the limit
        % of its travel)
        g.update();
        
        V1 = [g.pos,sensor1.Read()];
        V2 = [g.pos,sensor2.Read()];
        V3 = [g.pos,sensor3.Read()];
        
        v1(end+1,:)=V1;
        v2(end+1,:)=V2;
        v3(end+1,:)=V3;
        
        if ~g.isMoving % If the gantry has finished moving (or hasn't started)
            
            
            while g.pos <[XstartPos+Xarea YstartPos+Yarea] %while the gantry hasn't reached opposite corner
                
                %PATTERN
                g.moveTo(this, 0, res)
                g.moveTo(this, , res)
                g.moveTo(this, x3, 0)
                g.moveTo(this, -x4, y4)
                
                
               y1 and x3 are determine of the resolution
                %
                %
                %         % End the loop if the pattern is finished
                %         if i > length(pattern)
                %             break;
                %         end
                %
                %         % Start the gantry moving towards the ith point in the pattern
                %         g.moveTo(pattern(i, 1), pattern(i, 2));
                %
                %         i = i+1; % Move i to the next point in the pattern
                
                
            end
        end
        
    end
else flip pattern
    %Considering the boundaries and the resolution
    %Pattern:
    %motion in y direction depending on res
    %motion reverse diagonal
    %motion in x direction
    
    
    %%%CALIBRATE RECORDED DATA BY IMPLEMENTING OFFSETS%%%
    
    %%Initialise relative position to each other%%
    %Assume the triangular shaped display is right below the gantry
    
    %  S3
    
    %  0,0
    
    %S1          S2
    
    d=20; %in mm
    
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
    
    v1.Update=[x1+x1offset y1+y1offset z1]; %gives us [x y z1]
    v2.Update=[x2+x2offset y2+y2offset z2]; %gives us [x y z2]
    v3.Update=[x3+x3offset y3+y3offset z3]; %gives us [x y z3]






