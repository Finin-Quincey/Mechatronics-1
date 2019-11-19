classdef gantryMode
    
    enumeration
        PROGRAMMED("Programmed")
        MANUAL("Manual")
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