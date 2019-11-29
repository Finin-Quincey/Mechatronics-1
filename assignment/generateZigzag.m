function pattern = generateZigzag(resolution, size)
% Generates a zigzag pattern in a square area. The resolution need not
% divide exactly into the area dimensions.
% This is a disgusting way of doing it but it was quick and easy to write!

pattern = [];

x = 0;
y = resolution;

x1 = 0;
y1 = 0;

% SW half
while true
  
    pattern(end+1, :) = [x, 0];
    if x >= size
        x1 = x - size;
        y1 = x - size;
        hitNorth = true;
        pattern(end, :) = [size, 0];
        break;
    end
    x = x + resolution;
    
    pattern(end+1, :) = [x, 0];
    if x >= size
        x1 = x - size;
        y1 = x - size;
        hitNorth = true;
        pattern(end, :) = [size, 0];
        % I don't know why this one's different but it works
        pattern(end+1, :) = [size, y1];
        y1 = y1 + resolution;
        break;
    end
    x = x + resolution;
    
    pattern(end+1, :) = [0, y];
    if y >= size
        x1 = y - size;
        y1 = y - size;
        hitNorth = false;
        pattern(end, :) = [0, size];
        break;
    end
    y = y + resolution;
    
    pattern(end+1, :) = [0, y];
    if y >= size
        x1 = y - size;
        y1 = y - size;
        hitNorth = false;
        pattern(end, :) = [0, size];
        break;
    end
    y = y + resolution;
    
end

flag = false;

% NE half
while true
    
    if flag || hitNorth % Will skip this part for the first loop iteration if we hit the east side first
        
        pattern(end+1, :) = [x1, size];
        if x1 > size
            pattern(end, :) = [size, size];
            break;
        end
        x1 = x1 + resolution;
        
    end
        
    pattern(end+1, :) = [x1, size];
    if x1 > size
        pattern(end, :) = [size, size];
        break;
    end
    x1 = x1 + resolution;
    
    pattern(end+1, :) = [size, y1];
    if y1 > size
        pattern(end, :) = [size, size];
        break;
    end
    y1 = y1 + resolution;
    
    pattern(end+1, :) = [size, y1];
    if y1 > size
        pattern(end, :) = [size, size];
        break;
    end
    y1 = y1 + resolution;
    
    flag = true;
    
end

disp(hitNorth);

% And in theory, order has now emerged from the absolute chaos above!

end