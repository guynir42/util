function obj = load_defaults(obj)
% Takes the default values of an instance object and copies each property 
% default_XXXX to "XXXX" property. Should be used when initializing. 
% Need to make sure to manually reset all switches of the object as well. 

%     list = util.oop.list_props(obj);

    list = properties(obj);
    
    for ii = 1:length(list)
        
        name = ['default_' list{ii}];
        if isprop(obj, name)
            obj.(list{ii}) = obj.(name);
        end
        
    end


end