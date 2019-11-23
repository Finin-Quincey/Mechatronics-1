%Script that takes the recorded data of each sensors, input the offset
%relative to the aboslute position of the gantry, then interpolate this
%data, put a threshol, find epicenter and get neat surfaceplot.

%%Record Data%%

%Sensor 1 Data: v1=[x1 y1 z1]; 
%Sensor 2 Data: v2=[x2 y2 z2];  
%Sensor 3 Data: v3=[x3 y3 z3]; 

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

%Assign columns to a variable
x=v1(:,1);
y=v1(:,2);
z1=v1(:,3);
z2=v2(:,3);
z3=v3(:,3);

[xq,yq] = meshgrid(x,y); % returns 3-D grid coordinates defined by the vectors x, y, and z

G1 = griddata(x,y,z1,xq,yq,'cubic');
G2 = griddata(x,y,z2,xq,yq,'cubic');
G3 = griddata(x,y,z3,xq,yq,'cubic');

surf(xq,yq,G1) %Surfplot
hold on
surf(xq,yq,G2)
surf(xq,yq,G3)

%Apply a threshold
%Removes all data points that are below 2.6

for i = 1:size(G1)
    for j= 1:size(G1)
        if G1(i,j) < 2.55
            G1(i,j) = 0;
        end
    end
end


for i = 1:size(G2)
    for j = 1:size(G2)
        if G2(i,j) < 2.55
            G2(i,j) = 0;
        end
    end
end

for i = 1:size(G3)
    for j = 1:size(G3)
        if G3(i,j) < 2.55
            G3(i,j) = 0;
        end
    end
end
 
surf(xq,yq,G1)
hold on
surf(xq,yq,G2)
surf(xq,yq,G3)
colorbar



 











