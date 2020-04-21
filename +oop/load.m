function obj = load(filename, varargin)
% loads an object saved as txt, HDF5 or mat file.
% usage: obj = load(filename, varargin). 
%
% OPTIONAL ARGUMENTS 
%   -format: use TXT, HDF5, or MAT. Default is MAT or decided by filename. 
%   -recursive: check whether to load all sub-objects saved in the file. Default is 1. 
%   -location: where the object is located in the file (HDF5 only). Default is '/'. 
%   -classname: For older HDF5 files, need to specify what kind of object.
%   -name: use this to load specific object from MAT file. Default is
%    filename or first object in the file. 
%   -debug_bit: used for debugging only (Default is 0).
%   -handle_list: cell array of objects and link addresses, so that each
%    handle object is only loaded once. Filled by the function itself. 
%   -load_list: a cell array with each object's location, class and data, 
%    where data is stored as a cell array of strings.  This is
%    generated at launch of "load" and used to build all objects and link
%    them recursively as needed (text files only). 

    import util.text.cs;

    if nargin==0
        
        help('util.oop.load');
        
        if nargout>0
            obj = [];
        end
        
        return;
        
    end
        
    input = util.text.InputVars;
    input.input_var('format', [], 'type');
    input.input_var('location', '/');    
    input.input_var('classname', '');
    input.input_var('recursive', 1);
    input.input_var('data_save', 1);
    input.input_var('debug_bit', 0);
    input.input_var('handle_list', {});
    input.input_var('load_list', {});
    input.scan_vars(varargin);
%     input.printout;
    
    if isempty(input.format) && ischar(filename)
        [~,~,ext] = fileparts(filename);

        if ~isempty(ext)
            if cs(ext(2:end), 'mat')
                input.format = 'mat';
            elseif cs(ext(2:end), 'hdf5', 'h5', 'h5z')
                input.format = 'hdf5';
            elseif cs(ext(2:end), 'text', 'txt')
                input.format = 'text';
            else
                error(['Unknown file extension/type "' ext '", use .mat or .hdf5 or .txt']);
            end
        end
        
    end
    
    % if we want to just use the MAT format (this is the default if no ext exists
    if isempty(input.format) || cs(input.format, 'mat')
        obj_struct = load(filename);
        [~, filename] = fileparts(filename);
        if isfield(obj_struct, filename)
            obj = obj_struct(filename);
        else
            f = fields(obj_struct); 
            if ~isempty(f)
                obj = obj_struct.(f{1});
            else
                error('No objects are saved in this file!');
            end
        end
        
        return; % don't bother with the more complicated stuff...
        
    end
    
    % allow for list of locations:
    obj = [];
    
    if iscell(input.location)
        location_list = input.location;
    else
        location_list = {input.location};
    end
    
    for ii = 1:length(location_list)
        
        input.location = location_list{ii};
        
        try 
            if cs(input.format, 'hdf5', 'h5', 'h5z')
                obj = loadHDF5(filename, input);
            elseif cs(input.format, 'text', 'txt')
                obj = loadText(filename, input);
            else
                error(['Unknown file format "' input.format '". Use HDF5 or TXT or MAT...']); 
            end
        
        catch ME
            if ~strcmp(ME.identifier, 'MATLAB:imagesci:h5info:unableToFind') % if we couldn't find this object in that location, try others
                rethrow(ME); 
            end
        end
        
    end
    
    if isempty(obj)
        rethrow(ME); 
    end
    
end

function obj = loadHDF5(filename, input)

    import util.text.cs;
    import util.text.sa;
    
    fid = H5F.open(filename);
    fid_cleanup = onCleanup(@() H5F.close(fid));
    
    if input.location(1)~='/'
        input.location = ['/' input.location];
    end
    
    info = h5info(filename, input.location); % lists sub-groups, datasets and attributes...
        
    if isempty(info.Attributes) % no attributes here, go to lower groups...
       if ~isfield(info, 'Groups') || isempty(info.Groups)
           error(['No objects found in location: ' input.location']);
       else
           input.location = sa(input.location, info.Groups(1).Name);
           obj = loadHDF5(filename, input); % go deeper recursively
       end
    else % to load an object it must have attributes... (maybe add loading for datasets only...)
        
        att_names = {info.Attributes.Name}';
        
        if ~isfield(info, 'Groups') || isempty(info.Groups)
            group_names = {};
        else
            group_names = {info.Groups.Name}';
        end
           
        if ~isfield(info, 'Datasets') || isempty(info.Datasets)
            data_names = {};
        else
            data_names = {info.Datasets.Name}';
        end
        
        try % if it isn't H5G maybe it is H5D
            gid = H5G.open(fid, input.location);
            gid_cleanup = onCleanup(@() H5G.close(gid));
        catch 
            gid = H5D.open(fid, input.location);
            gid_cleanup = onCleanup(@() H5D.close(gid));
        end
        
        idx = find(contains(att_names, 'object_classname'),1);
        
        if ~isempty(idx)
            class_name = loadAttHDF5(gid, 'object_classname');            
            if input.debug_bit, disp(['Constructing a ' class_name ' object...']); end
            obj = feval(class_name);

            if isa(obj, 'handle')
                input.handle_list{end+1} = {input.location, obj};
            end
        elseif ~isempty(input.classname)
            obj = feval(input.classname);
        else
            error('Unknown class...');
        end

        for ii = 1:length(att_names) % load all attributes saved in the file

            % check if attribute can even be loaded into object...
            if strcmp(att_names{ii}, 'object_classname') 
                continue; % already used this one to construct the object         
            elseif isprop(obj, att_names{ii})
                if input.debug_bit, disp(['loading attribute ' att_names{ii} ' as part of object...']); end                
            elseif isa(obj, 'dynamicprops')
                if input.debug_bit, disp(['loading attribute ' att_names{ii} ' and adding it to dynamic object...']); end
                addprop(obj, att_names{ii});
            else 
                if input.debug_bit, disp(['attribute ' att_names{ii} ' is not part of object...']); end
                continue;
            end

            try
                
                value = loadAttHDF5(gid, att_names{ii});

                if ~isempty(value) && ischar(value) && contains(value, class(obj.(att_names{ii}))) && contains(value, '(link: /')
                    if ~input.recursive
                        continue;
                    end
                    
                    idx = strfind(value, '(link: /');
                    sublocation = strip(value(idx+6:end-1)); % load object from sublocation pointed to by string value
                    
                    val = checkList(input.handle_list, sublocation); % try to get a pre-loaded object from handle_list
                    
                    if isempty(val) % if no such object is found, search sub-groups...
                        
                        expr = [sublocation '(\(\d\))?$']; % look for any groups that match the sublocation with added (#) for vector of objects
                        idx = ~cellfun(@isempty, regexp(group_names, expr));
                        
                        sublocation = group_names(idx);
                        
                        for jj = 1:length(sublocation)
                        
                            try
                                temp_obj = util.oop.load(filename, input.output_vars{:}, 'location', sublocation{jj});
                            catch ME
                                warning(['ERROR: loading sub-object ' att_names{ii} ': ' getReport(ME)]);
                            end

                            loaded_obj(jj) = temp_obj;
                            
                        end
                        
                    else
                        loaded_obj = val;
                        if input.debug_bit, disp(['already loaded object "' att_names{ii} '"... in handle list at ' sublocation]); end
                    end
                    
                    obj.(att_names{ii}) = loaded_obj;
                    clear('loaded_obj');

                else % load a regular attribute...
                    mp = findprop(obj, att_names{ii});
                    if isa(obj.(att_names{ii}), 'datetime') && ischar(value)
                        obj.(att_names{ii}) = util.text.str2time(value); 
                    elseif ~isobject(obj.(att_names{ii})) % skip over loading objects
                        try
                            if isempty(value)
                                obj.(att_names{ii}) = feval([class(obj.(att_names{ii})) '.empty']);
                            elseif ischar(value) && isa(obj.(att_names{ii}), 'datetime')
                                obj.(att_names{ii}) = util.text.str2time(value);
                            else
                                obj.(att_names{ii}) = value;
                            end
                        end
                    end
                end

            catch ME
                warning(['ERROR loading attribute "' att_names{ii} '": ' getReport(ME)]);
            end

        end % for ii = 1:length(att_names)
        
        for ii = 1:length(data_names) % load all datasets saved in the file
            
            if isprop(obj, data_names{ii})
                if input.debug_bit, disp(['loading data ' data_names{ii} ' as part of object...']); end                
            elseif isa(obj, 'dynamicprops')
                if input.debug_bit, disp(['loading data ' data_names{ii} ' and adding it to dynamic object...']); end
                addprop(obj, data_names{ii});
            else 
                if input.debug_bit, disp(['data ' data_names{ii} ' is not part of object...']); end
                continue;
            end
            
            % assumes no empty datasets, and if there are, they should be just an empty double array 
            mp = findprop(obj, data_names{ii});
            if mp.Dependent==0 % skip over loading of Dependent properties...
                obj.(data_names{ii}) = loadDataHDF5(gid, data_names{ii});
            end
            
        end % for 1:lengtH(data_names)
        
    end
    
end

function val = loadAttHDF5(group_id, name)

    attr_id = H5A.open(group_id, name);
    attr_id_cleanup = onCleanup(@() H5A.close(attr_id));
    
    val = util.vec.torow(H5A.read(attr_id));
    
end

function val = loadDataHDF5(group_id, name)

    data_id = H5D.open(group_id, name);
    data_id_cleanup = onCleanup(@() H5D.close(data_id));
    
    val = H5D.read(data_id);
    
end

function obj = loadText(filename, input)

    file_id = fopen(filename);
    file_id_cleanup = onCleanup(@() fclose(file_id));
    
    input.load_list = makeLoadList(file_id); % picks up all we need from the text file...

    obj = buildObjectFromList(input.location, input); % build the first object (calls this function recursively to build the rest)
        
end

function list = makeLoadList(file_id)

    list = {};
    
    for ii = 1:1000000
           
        line = fgetl(file_id);
        if isnumeric(line) && line<0
            break;
        end
        
        if ~isempty(regexp(line, 'OBJECT.*CLASS.*LOCATION.*'))
            
            [idx1, idx2] = regexp(line, 'CLASS:.+\|', 'once'); % get the part of the header that holds the class name.
            
            classname = strip(line(idx1+length('CLASS:'):idx2-1));
                        
            [idx1, idx2] = regexp(line, 'LOCATION:.+', 'once'); % get the part of the header that holds the location
            
            location = strip(line(idx1+length('LOCATION:'):end));
            
            list{end+1} = {location,classname,{}};
            continue;
        end
        
        if ~isempty(list)
            list{end}{3}{end+1} = line;
        end
        
    end

end

function obj = buildObjectFromList(location, input)
% the reason I give location independently from input is because I call 
% this function recursively using sublocations.
    
    if isempty(location) || strcmp(location, '/')
        idx = 1; % if not given location in file, just take first object
    else
        idx = [];
        for ii = 1:length(input.load_list)
            if regexp(input.load_list{ii}{1}, [location '(\(\d+\))?'])
                idx(end+1) = ii;
                break;
            end            
        end
        if isempty(idx), error(['Cannot find location ' location ' in TXT file load list...']); end
    end
    
    for ii = 1:length(idx)

        location = input.load_list{idx(ii)}{1};
        classname = input.load_list{idx(ii)}{2};
        txt = input.load_list{idx(ii)}{3};

        obj(ii) = feval(classname); % create a default object

        if isa(obj, 'handle')
            input.handle_list{end+1} = {location, obj};
        end

        for jj = 1:length(txt)

            line = strip(txt{jj});

            try 
                if ~isempty(line)
                    obj = readPropertyFromList(obj, line, input);
                end
            catch ME
                warning(['ERROR when reading line: ' line ': ', getReport(ME)]);
            end

        end

    end
    
end

function obj = readPropertyFromList(obj, line, input)
    
    idx = regexp(line, ':', 'once');
    
    name = strip(line(1:idx-1));
    str = strip(line(idx+1:end));
    
    idx = regexp(name, '[\(|\{]\d+[\)|\}]', 'once'); % check if the name contains brackets
        
    if ~isempty(idx)
        propname = name(1:idx-1);
    else
        propname = name;
    end
            
    if ~isprop(obj, propname)
        if isa(obj, 'dynamicprops')
            addprop(obj, propname);
        else
            if input.debug_bit, disp(['Not loading property ' propname ' as it doesnt exist in ' class(obj)]); end
            return;
        end
    end
    
    mp = findprop(obj, propname);
    if mp.Dependent
        if input.debug_bit, disp(['Property ' propname ' is Dependent. Skipping...']); end
        return;
    end
    
    if isa(obj.(propname), 'datetime')
        if input.debug_bit, disp(['Property ' propname ' is "datetime". Reading using util.text.str2time...']); end
        value = util.text.str2time(str);            
    elseif isobject(obj.(propname)) && (isempty(str) || strcmp(str, '[]'))
        if input.debug_bit, disp(['Property ' propname ' is an empty object of type ' class(obj.(propname)) '...']); end
        value = feval([class(obj.(propname)) '.empty']);
    elseif isempty(str)
        if input.debug_bit, disp(['Property ' propname ' is empty. Setting to [].']); end
        value = [];
    else
        
        num = str2num(str);
        
        if strcmp(str, '[]') % empty double
            if input.debug_bit, disp(['Property ' propname ' is empty double. Setting [].']); end
            value = [];
        elseif strcmp(str, '{}') % empty cell array
            if input.debug_bit, disp(['Property ' propname ' is empty cell. Setting {}.']); end
            value = {}; 
        
        elseif regexp(str, '\[\d+x\d+.*\]') % matrix/object array

            idx = regexp(str, '(link: '); % check if it is linked...

            if ~isempty(idx) % assume it is a linked object
                
                if input.recursive % recursively load objects...

                    sublocation = strip(str(idx+length('(link: '):end-1));
                    
                    value = checkList(input.handle_list, sublocation); % try to get a pre-loaded object from handle_list
                    
                    if isempty(value)
                        if input.debug_bit, disp(['loading property ' name ' as object from location: ' sublocation]); end
                        value = buildObjectFromList(sublocation, input);
                    else
                        if input.debug_bit, disp(['loading property ' name ' from handle_list...']); end
                    end

                else
                    if input.debug_bit, disp(['ignoring property ' name ' since it is an object (non-recursive load)']); end
                    return;
                end

            else % assume it is data (some matrix or long vector)
                if input.debug_bit, disp(['Property ' propname ' is data-type. Skipping...']); end
                return; % skip over matrices/data (leave it as is!)
            end
        elseif isempty(num) % just a string attribute
            if input.debug_bit, disp(['Property ' propname ' is a string. Copying...']); end
            value = str; 
        elseif isnumeric(num) % a numeric scalar/short vector
            if input.debug_bit, disp(['Property ' propname ' is numeric. Copying...']); end
            value = num; 
        end % else-if for type of str
        
    end % if ~isempty(str)
    
    eval(['obj.' name ' = value;']); % load the value into the object, including all sorts of weird brackets in the name. 
    
end

function loaded_obj = checkList(list, location)

    for ii = 1:length(list)
        if strcmp(list{ii}{1}, location)
            loaded_obj = list{ii}{2};
            return;
        end
    end
    
    loaded_obj = [];

end



