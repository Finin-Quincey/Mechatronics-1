%%%%%%%%%%%%%%%%%%%%%%TREASURE HUNT%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%PREPARE THE HUNT%%%%%%%%%%%%%

%Setup the Arduino
clear all
george = arduino("COM5", "Mega2560", "Libraries", "RotaryEncoder");

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

sensor1 = HallSensor(george, "A2");
sensor2 = HallSensor(george, "A1");
sensor3 = HallSensor(george, "A0");
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
% 
% %ZigZagScan of the entire beach.
% %Outputs 3 matrices with signals detected from each sensor
[v1Update,v2Update,v3Update] = zigzagScan(george, g, sensor1, sensor2, sensor3);
% 
% %Interpolate the data
% 
% %Assign columns to a variable
% x=v1(:,1);
% y=v1(:,2);
% z1=v1(:,3);
% z2=v2(:,3);
% z3=v3(:,3);
% 
% %Apply a threshold - only consider signals above that threshold
% for i = 1:size(z1, 1)
%     for j= 1:size(z1, 2)
%         if z1(i,j) < 2.55
%             z1(i,j) = 0;
%         end
%     end
% end
% 
% for i = 1:size(z2, 1)
%     for j= 1:size(z2, 2)
%         if z2(i,j) < 2.55
%             z2(i,j) = 0;
%         end
%     end
% end
% 
% for i = 1:size(z3, 1)
%     for j= 1:size(z3, 2)
%         if z3(i,j) < 2.55
%             z3(i,j) = 0;
%         end
%     end
% end
% 
% %Clean the data - interpolate to get a more accurate data
% [xq,yq] = meshgrid(1:0.2:length(x),1:0.2:length(y)); % increase the steps between each x-y values
% 
% G1 = griddata(x,y,z1,xq,yq,'cubic'); %intropolated the data recorded according to these intropolated x-y values.
% G2 = griddata(x,y,z2,xq,yq,'cubic');
% G3 = griddata(x,y,z3,xq,yq,'cubic'); 
% 
% %%%%%%%%%%%%%% THE LOCATIONS OF THE TREASURES %%%%%%%%%%%%%%
% %Determine the epicenters from data.
% 
% %Merge the data recorded by the 3 sensors 
% beachScan=G1+G2+G3; 
% 
% treasurePeaks = imregionalmax(beachScan); % returns the binary image that identifies the regional maxima in matrix. .
% [Xpeaks,Ypeaks]=find(treasurePeaks ==1);% returns the x-y coordinates of those peaks.
% 
% treasureCoord=[Xpeaks,Ypeaks]; %creates 2-columns matrix with x-y coordinates
% 
% %Classify from the furthest to closest 
% treasureOrder = sortrows(treasureCoord,2,'descend');
% %sorts A based on the columns specified in the vector column.
% %in descending order
% 
% numberTreasures=length(treasureCoord); %the number of treasures is equal to the nbr of peaks found
% 
% %%%%%%%%%%%%%%%% COLLECTION OF CUPS, GO TO TREASURE & COVER IT %%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%% AND REPEAT UNTILL ALL TREASURES COVERED%%%%%%%%%%%%%%%%%%%%
% 
% %2 stacks of cups located: 1. under home 2. just next to 1 in y direction
% 
% stack1XY=[0 0]; %center of stack
% stack2XY=[0 80];
% 
% nCups=5; %number of cups per stack
% % cupHeight=(38-7.5);% 24.5mm
% % betweenCups=13; %in mm 
% % maxHeight=(4*betweenCups)+cupgrabHeight; %topcup will be grabbed at%76.5
% % heightDiff= 7.5*2; %14mm
% 
% cupHeights=[76.5 % topCup 1
%             62.5 % Cup 2
%             48.5 % Cup 3
%             34.5 % Cup 4
%             20.5]; %lastCup 5
% i=0;
% j=1;
% treasuresLeft=numberTreasures;
% 
% while treasuresLeft>0 % while the is still some treasures to be covered.
%     for i=1:nCups & j=1:numberTreasures %if there is still some cups in stack 1
%         
%     g.moveTo(stack1XY);
%     height=cupHeight(i,1);
%     arm.movetoheight(this,height,down,pins); %lower the arm to top cup height.
%     gripper.grab; 
%     height=highPos;
%     arm.movetoheight(this,height,up,pins);% higher to high pos
%     
%     g.moveTo(treasureOrder(j,j));
%     
%     height=dropPos;
%     arm.movetoheight(this,height,down,pins);
%     gripper.release;
%     
%     height=highPos;
%     arm.movetoheight(this,height,down,pins);
%     
%     treasuresLeft= numberTreasures - 1;
%     i=i+1;
%     j=j+1;
%     else
%         g.moveTo(stack2XY);
%         end
%     end
% end
% 
