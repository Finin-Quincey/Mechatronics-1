%%%%%%%%%%%%%%%%%%%%%%TREASURE HUNT%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%PREPARE THE HUNT%%%%%%%%%%%%%

%Setup the Arduino
clear
george =arduino("COM5","Mega2560");

%Setup of Gantry & Hall Sensor 
g = gantry(george, "D9", "D11", "D10", "D8", "D7", "D6", "D4");
sensor1 = HallSensor(george, "A2");
sensor2 = HallSensor(george, "A1");
sensor3 = HallSensor(george, "A0");
arm= arm();
gripper=gripper();

g.mode = gantryMode.PROGRAMMED; % Allow this script to control the updates
updatePeriod = 0.05;

%Initialise the Gantry position
g.calibrate;

if g.pos==[0 0]
    break
    
%%%%%%%%%%%%%%SCAN FOR TREASURES%%%%%%%%%%%%%

%ZigZagScan of the entire beach.
%Outputs 3 matrices with signals detected from each sensor
[v1Update,v2Update,v3Update] = zigzagScan(a, this.gantry,this.sensor1,this.sensor2,this.sensor3);

%Interpolate the data

%Assign columns to a variable
x=v1(:,1);
y=v1(:,2);
z1=v1(:,3);
z2=v2(:,3);
z3=v3(:,3);

%Apply a threshold - only consider signals above that threshold
for i = 1:size(z1, 1)
    for j= 1:size(z1, 2)
        if z1(i,j) < 2.55
            z1(i,j) = 0;
        end
    end
end

for i = 1:size(z2, 1)
    for j= 1:size(z2, 2)
        if z2(i,j) < 2.55
            z2(i,j) = 0;
        end
    end
end

for i = 1:size(z3, 1)
    for j= 1:size(z3, 2)
        if z3(i,j) < 2.55
            z3(i,j) = 0;
        end
    end
end

%Clean the data - interpolate to get a more accurate data
[xq,yq] = meshgrid(1:0.2:length(x),1:0.2:length(y)); % increase the steps between each x-y values

G1 = griddata(x,y,z1,xq,yq,'cubic'); %intropolated the data recorded according to these intropolated x-y values.
G2 = griddata(x,y,z2,xq,yq,'cubic');
G3 = griddata(x,y,z3,xq,yq,'cubic'); 

%%%%%%%%%%%%%% THE LOCATIONS OF THE TREASURES %%%%%%%%%%%%%%
%Determine the epicenters from data.

%Merge the data recorded by the 3 sensors 
beachScan=G1+G2+G3; 

treasurePeaks = imregionalmax(beachScan); % returns the binary image that identifies the regional maxima in matrix. .
[Xpeaks,Ypeaks]=find(treasurePeaks ==1);% returns the x-y coordinates of those peaks.

treasureCoord=[Xpeaks,Ypeaks]; %creates 2-columns matrix with x-y coordinates

nbrTreasures=length(treasureCoord); %the number of treasures is equal to the nbr of peaks found

%%%%%%%%%%%%%% THE SHORTEST COLLECTION PATH %%%%%%%%%%%%%%







