function copy_props(obj_to, obj_from, deep, include_empty_dynamic_props)
% Usage: copy_props(obj_to, obj_from, deep=0, include_empty_dynamic_props=0)
% Copies the properties of obj_from into the properties of obj_to. 
% *deep: make copies of sub objects as well (default 0). 
% *include_empty_dynamic_props: for objects with dynamic properties, if a 
%  property in obj_from doesn't exist in obj_to, it is usually added 
%  dynamically. If it is empty, only add it when this argument is set to 1. 
%  (default 0, as empty properties are usually not interesting enough). 

    if nargin==0, help('util.oop.copy_props'), return; end
    
    if nargin<2 || isempty(obj_to) || isempty(obj_from)
        error('must supply two objects to "copy_props"');
    end
    
    if ~isa(obj_to, class(obj_from))
        error(['Class mismatch between objects... class(obj_to)= "' class(obj_to) '" | class(obj_from)= "' class(obj_from) '"']);
    end
    
    if nargin<3 || isempty(deep)
        deep = 0;
    end
    
    if nargin<4 || isempty(include_empty_dynamic_props)
        include_empty_dynamic_props = 0;
    end
    
    props = properties(obj_from);
%     props_to = properties(obj_to); % I thought maybe to combine this with
%     util.text.cs instead of isprop, to do case-insensitive search. But I
%     feel this is not safe (for classes without case-insensitivity).
    
    for ii = 1:length(props)
        
        name = props{ii};
        p = findprop(obj_from, name);
        
        if p.Dependent==0
            
%             if ~isprop(obj_to, name) % no such property in obj_to               
            try
                obj_to.(name);
            catch ME
                if strcmp(ME.identifier,'MATLAB:noSuchMethodOrField') % this property really REALLY doesn't exist in the obj_to (not even partial-case-insensitive matches)
                    if isa(obj_to, 'dynamicprops') % maybe it is a dynamicprops type
                        if include_empty_dynamic_props==0 && isempty(obj_from.(name))
                            continue; % don't want to copy new properties that are empty!
                        else
                            addprop(obj_to, name);
                        end
                    else
                        continue; % no luck, skip to next property
                    end
                else
                    rethrow(ME); % other kinds of errors?
                end
            end
            
            try 
                if deep && isa(obj_from.(name), 'handle')
                    obj_to.(name) = util.oop.full_copy(obj_from.(name)); % need to change this so it handles circular references...
                else
                    obj_to.(name) = obj_from.(name);
                end
            catch ME
                if ~strcmp(ME.identifier, {'MATLAB:class:noSetMethod', 'MATLAB:index:assignmentToTemporary'}) % if somehow the obj_to property is dependent...
                    rethrow(ME);
                end
            end
        end
        
    end
    
end