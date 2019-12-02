
%% PROCESS THE DATA! %%
% Offset data down by base voltage of hall sensor
z = z - 2.55;

% Take magnitude of values
z = abs(z);

% Apply a threshold - only consider signals above that threshold
% This cuts out all the noisy background data, we don't want to detect
% hundreds of tiny peaks!
for i = 1:size(z, 1)
    for j= 1:size(z, 2)
        if z(i,j) < 0.05
            z(i,j) = 0;
        end
    end
end

% Clean the data - interpolate to get a more accurate data
[xq, yq] = meshgrid(1:2:length(x), 1:2:length(y)); % 2mm steps between each x-y value

G = griddata(x, y, z, xq, yq,'cubic'); % Interpolate the data recorded according to these finer x-y values

G(isnan(G)) = 0; 

% Determine the epicenters from data

treasurePeaks = imregionalmax(G); % Returns the binary image that identifies the regional maxima in matrix
[Xpeaks, Ypeaks] = find(treasurePeaks == 1); % Returns the x-y coordinates of those peaks

treasureCoord = [Xpeaks, Ypeaks]; % Creates 2-columns matrix with x-y coordinates

% Randomised treasure positions for testing gantry/arm/gripper movement
treasureCoord = [
    rand * g.limits(1), rand * g.limits(2);
    rand * g.limits(1), rand * g.limits(2);
    rand * g.limits(1), rand * g.limits(2);
    rand * g.limits(1), rand * g.limits(2);
    rand * g.limits(1), rand * g.limits(2);
    rand * g.limits(1), rand * g.limits(2);
    rand * g.limits(1), rand * g.limits(2);
    rand * g.limits(1), rand * g.limits(2);
];

% Classify from the furthest to closest 
treasureOrder = sortrows(treasureCoord, 2, 'descend');
% Sorts coords based on the columns specified in the vector column
% In descending order

% The number of treasures is equal to the nbr of peaks found
numberTreasures = length(treasureCoord);