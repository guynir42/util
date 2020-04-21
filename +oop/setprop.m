function setprop(obj_vec, prop, val)
% Usage: setprop(obj_vec, prop, val). Sets the property "prop" for each 
% element in "obj_vec" to val. 
% At this point doesn't handle 3D matrices... 

    if nargin==0
        help('util.oop.setprop');
        return;
    end
    
    if isprop(obj_vec(1), prop) || isfield(obj_vec(1), prop)
        
        for ii = 1:size(obj_vec,1)
            for jj = 1:size(obj_vec,2)
                obj_vec(ii,jj).(prop) = val;
            end
        end
        
    else
        error(['property: "' prop '" is not part of "' inputname(1) '"']);
    end
    
end