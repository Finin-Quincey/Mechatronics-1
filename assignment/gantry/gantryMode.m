classdef gantryMode
    
    % GANTRYMODE Simple enum class to define the gantry modes
    
    enumeration
        PROGRAMMED("programmed")
        MANUAL("manual")
    end
    
    properties(SetAccess = immutable)
        name
    end
    
    methods
        
        function this = gantryMode(name)
            this.name = name;
        end
        
    end
    
end