classdef direction
    % DIRECTION Set of enumeration constants representing the cardinal
    % (compass) directions: N, NE, E, SE, S, SW, W and NW.
    % Each direction has two properties, x and y, which define the signal
    % to be supplied to the direction pin. If the value for x or y is NaN,
    % that axis does not move.
    
    enumeration
        NOWHERE(nan, nan) % For the sake of completeness!
        N(1, nan)
        NE(1, 1)
        E(nan, 1)
        SE(0, 1)
        S(0, nan)
        SW(0, 0)
        W(nan, 0)
        NW(1, 0)
    end
    
    properties(SetAccess = immutable)
        x
        y
    end
    
    methods
        
        function this = direction(xDir, yDir)
            this.x = xDir;
            this.y = yDir;
        end
        
    end
end

