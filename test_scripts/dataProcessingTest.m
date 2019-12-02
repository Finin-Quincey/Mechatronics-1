% Test data
G = peaks(200);
xq = 1:200;
yq = 1:200;

treasureCoord = [];
r = 50; %radius of cercle corresponding to cup diameter

% Determine the epicenters from data
while max(G, [], 'all') > 2
    
    % Find max value over all elements.
    maxPoint = max(G,[],'all'); % finds the maximum over all elements of G.
    
    % Returns the x-y coordinates of that peak
    [Xindex, Yindex] = find(G == maxPoint);  %returns a vector containing the linear indices of each nonzero element in array G.
    
    % Convert those indices in the x-y position
    Xpeak = xq(Xindex);
    Ypeak = yq(Yindex);
    
    % Store those coordinates into a 2-columns matrix
    treasureCoord(end+1, :) = [Ypeak, Xpeak]; % No idea why this needs x and y flipped but it works
    
    % Erase values that are within a radius from max point
    G = (bwdist(G == maxPoint) >= r) .* G; %this would cut reduce the initia scquare into a circle by cutting off edges

    h = figure;
    surf(G);
    hold on
    scatter3(treasureCoord(:, 1), treasureCoord(:, 2), ones(size(treasureCoord, 1), 1) * 10, 'ro');
    
    input('Press any key to continue');
    
    close(h);
    
end