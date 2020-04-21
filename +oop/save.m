function file_handle = save(obj, filename, varargin)
% Usage: file_handle = save(obj, filename, varargin). 
% Saves an object into a txt, HDF5 or mat file. 
%
% Will automatically convert all short properties into "attributes" and all
% long (data) properties into datasets. 
% Deciding on what is short and what is long depends on dimensionality, but
% for vectors the limiting length of an attribute is given by "att length"
% optional argument. 
%
% The "filename" argument can also be used as a file-handle to an open file. 
% If given as file-name, the extension is used to determine format (unless 
% the format is given by a keyword input). 
% 
% OPTIONAL ARGUMENTS:
%   -att_length: max. length of vector to be written down as attribute. 
%   -deflate: how much to compress the data (default is []: no deflation 
%    for HDF5 files, but uses compression for MAT files). 
%   -chunk: the size of tiles for compression (default is [64,64]). This is
%    only used on deflated HDF5 files. 
%   -location: the place inside the file where the object is saved (use for
%    sub-objects inside larger files). HDF5 only. 
%   -recursive: check this in order to save all sub-objects, too (default: 1)
%   -data_save: check if the object's data should be saved (or just 
%    attributes). For text files this is always 0. 
%   -format: type of file to save. Default is .mat but will also read the 
%    extension of "filename" if exists. Other options: hdf5, text.
%    Can also use "struct" option to output a cell array of attribute structs. 
%   -append: check this to append data to existing file (default: 0, 
%    so overwrites existing file). 
%   -name: the name of this object as it is shown in the file (default=inputname(1)).
%   -debug_bit: used for debugging only (Default is 0).
%   -handle_list: a cell array where each cell is a cell array with two parts, 
%    one a handle to a previously saved handle object, and another to the address
%    in the file where that object has been saved. Should be filled automatically
%    when calling "save" recursively. 

    import util.text.cs;
    import util.text.sa;

    if nargin==0
        help('util.oop.save');
        return;
    end
    
    if ~isempty(varargin) && isa(varargin{1}, 'util.text.InputVars')
        
        input = varargin{1};
        input.scan_vars(varargin{2:end});
        
    else
        
        input = util.text.InputVars;
        input.input_var('att_length', 10, 'attribute_length');
        input.input_var('deflate', [], 'zip', 'compress');
        input.input_var('chunk', [64,64]);
        input.input_var('location', '/');
        input.input_var('recursive', 1);
        input.input_var('data_save', 1);
        input.input_var('format', [], 'type');
        input.input_var('append', 0);
        input.input_var('name', inputname(1));
        input.input_var('hidden', 0, 'use_hidden', 5);
        input.input_var('dependent', 1, 'use_dependent', 5);
        input.input_var('table_full', 0); 
        input.input_var('debug_bit', 0);
        input.input_var('handle_list', {});

        input.scan_vars(varargin);
    
    end
    
    if builtin('isempty', obj), file_handle = filename; return; end
    
    % try to guess the format (if not given directly...)
    if isempty(input.format) && ischar(filename)
        [dirname,~,ext] = fileparts(filename);
        
        % make a directory if needed...
        if ~isempty(dirname) && ~exist(dirname, 'dir')
            mkdir(dirname);
        end
        
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
    
    % if we want to just use the MAT format (this is the default if no extension exists
    if isempty(input.format) || cs(input.format, 'mat')
        par_list = {filename, 'obj', '-v7.3'};
        
        if ~isempty(input.deflate) && input.deflate==0
            par_list = [par_list '-nocompression'];
        end
        
        if input.append
            par_list = [par_list, '-append'];
        end
        
        save(par_list{:}); 
        return; % don't bother with the more complicated stuff...
    end
    
    % if the filename is not given as file-handle, open a new file-handle
    if ischar(filename)
        if cs(input.format, 'hdf5', 'h5', 'h5z')
            
            H5.open;
            if input.append
                if ~exist(filename, 'file')
                    error('Cannot append, file does not exist: %s', filename);
                end
                
                try 
                    file_handle = H5F.open(filename, 'H5F_ACC_RDWR', 'H5P_DEFAULT');
                catch ME
                    disp(['problem saving file: ' filename]);
                    rethrow(ME);
                end
            else
                if exist(filename, 'file')
                    delete(filename);
                end
                
                file_handle = H5F.create(filename);
%                 file_handle_cleanup = onCleanup(@() H5F.close(file_handle));
                
            end
            
        elseif cs(input.format, 'text', 'txt')
            if input.append
                file_handle = fopen(filename, 'at');
            else
                file_handle = fopen(filename, 'wt');
            end
            file_handle_cleanup = onCleanup(@() fclose(file_handle));
        elseif cs(input.format, 'struct')
            file_handle = {};
        end
    else
        file_handle = filename; % if it isn't a string, must already be a handle
    end
    
    % if given a vector of objects, call "save" recursively on each one... 
    if length(obj)>1
        for ii = 1:length(obj)
            try 
            util.oop.save(obj(ii), file_handle, input.output_vars{:}, 'name', [input.name '(' num2str(ii) ')']);
            catch ME
                warning(['ERROR when calling "save" on object ' num2str(ii) ' in vector... ' getReport(ME)]);
            end
        end
        return; 
    end
    
    % make sure we are not saving the same (handle) object multiple times... 
    if input.recursive && isa(obj, 'handle')
        
        if isempty(checkList(obj, input.handle_list))
            input.handle_list{end+1} = {obj, sa(input.location, input.name)}; % add this object to the list, then save it... 
        else
            return; % don't save this object, it is already on the list...
        end
        
    end
    
    group_handle = saveHeader(file_handle, obj, input); % make a header / create new group for the object
    this_location = input.location; % keep the location of this object before recursively going into sub-objects
    
%     group_handle_cleanup = onCleanup(@() H5G.close(group_handle));
    
%     props = util.oop.list_props(obj); % get the property list, including dynamic properties... 
    if input.hidden
        warning off MATLAB:structOnObject;
        st = struct(obj);
        props = fieldnames(st);
    else
        props = properties(obj); % just get the good old fashioned, visible (non-hidden non-private) member names
    end
    
    % now go over the properties and save them all... 
    for ii = 1:length(props)
%         name = props{ii};
        name = props{ii};
        try
            p = findprop(obj, name);
            if p.Transient 
                if input.debug_bit, disp(['prop: "' name '" is transient. Skipping...']); end
            elseif input.dependent==0 && p.Dependent
                if input.debug_bit, disp(['prop: "' name '" is dependent. Skipping...']); end
            else
                group_handle = saveProperty(group_handle, name, obj.(name), input);
            end
            
        catch ME
            warning(['ERROR when saving "' name '": ' ME.getReport]);
        end
    end
    
    if cs(input.format, 'struct', 'cell')
        file_handle = group_handle; % keep passing around the cell array... 
    end
    
    % for text files (or struct), do another round for sub-objects...
    if cs(input.format, 'text', 'txt', 'struct', 'cell') && input.recursive
        try
            for ii = 1:length(props)
                
                name = props{ii};
                value = obj.(name);
                p = findprop(obj, name);
               
                if isobject(value) && p.Transient==0 && ~isa(value, 'table') && ~isa(value, 'datetime') && ~isa(value, 'containers.Map') && length(value)<2 && isempty(checkList(value, input.handle_list))
                    
                    if input.debug_bit, disp(['prop: "' name '" now saved as object...       **********************']); end
                    
                    file_handle = util.oop.save(value, file_handle, input, 'name', name, 'location', this_location);
                
                elseif isa(value, 'datetime') || isa(value, 'containers.Map') || isa(value, 'table')
                    continue;
                elseif isobject(value) && p.Transient==0 && numel(value)>1
                    
                    for jj = 1:numel(value)
                        
                        if ~isa(value(jj), 'datetime') && ~isa(value(jj), 'containers.Map') && isempty(checkList(value(jj), input.handle_list))
                        
                            if input.debug_bit, disp(['prop: "' name '(' num2str(jj) ')" now saved as object...']); end
                        
                            file_handle = util.oop.save(value(jj), file_handle, input.output_vars{:}, 'name', [name '(' num2str(jj) ')']);
                            
                        end
                                                
                    end
                    
                elseif iscell(value)
                    
                    for jj = 1:length(value)
                        
                        if isobject(value{jj}) && p.Transient==0 && ~isa(value{jj}, 'datetime') && length(value)<2 && isempty(checkList(value{jj}, input.handle_list))
                        
                            if input.debug_bit, disp(['prop: "' name '{' num2str(jj) '}" now saved as object...']); end
                        
                            file_handle = util.oop.save(value{jj}, file_handle, input.output_vars{:}, 'name', [name '{' num2str(jj) '}']);
                            
                        end
                        
                    end
                    
                end
                
            end
            
        catch ME
            warning(['ERROR when saving "' props{ii} '": ' ME.getReport]);
        end
    end
    
    if cs(input.format, 'hdf5', 'h5', 'h5z')
        H5G.close(group_handle);

        % if the filename was not given as file-handle, close the file-handle
        if ischar(filename)
            if cs(input.format, 'hdf5','h5', 'h5z')
                H5F.close(file_handle);
                H5.close;
            end
        end
    end

end

function file_handle = saveHeader(file_handle, obj, input)
    
    import util.text.cs;
    
    input.location = util.text.sa(input.location, input.name);
    
    if cs(input.format, 'hdf5', 'h5', 'h5z')
        
        link_create_properties = H5P.create('H5P_LINK_CREATE');
        link_create_properties_cleanup = onCleanup(@() H5P.close(link_create_properties));
        H5P.set_create_intermediate_group(link_create_properties,1); % I think this allows making all required groups down to the location of this dataset. 
        
        file_handle = H5G.create(file_handle, input.location, link_create_properties,'H5P_DEFAULT','H5P_DEFAULT'); % this is destroyed outside in the main function...
        
        saveString(file_handle, 'object_classname', class(obj), input);
        
    elseif cs(input.format, 'text', 'txt')
        fprintf(file_handle, '\n  OBJECT LOG FOR: "%s" | CLASS: %s | LOCATION: %s\n\n', input.name, class(obj), input.location);
    elseif cs(input.format, 'struct', 'cell')
        file_handle{end+1} = struct('save_struct_object_address', input.location, 'object_classname', class(obj)); % a new row in the output cell array of structs
    else
        error(['Unknown file type: ' input.format '... use HDF5 or TEXT.']);
    end
        
end

function file_handle = saveProperty(file_handle, name, value, input)
    
    if ischar(value)
        
        if input.debug_bit, disp(['prop: "' name '" is string. Writing as attribute...']); end
        
        file_handle = saveString(file_handle, name, value, input);
        
    elseif iscell(value)
        
%         if input.debug_bit, disp(['prop: "' name '" is cell array. Writing as as separate attributes/datasets...']); end
        
        if isempty(value)
            if input.debug_bit, disp(['prop: "' name '" is empty. Writing as attribute...']); end
            saveString(file_handle, name, '{}', input);
        elseif isvector(value) && (length(value)<=input.att_length ||  util.text.cs(input.format, 'hdf5', 'h5', 'h5z', 'struct', 'cell'))
            if input.debug_bit, disp(['prop: "' name '" is a short 1D cell array. Writing as individual attributes...']); end
            file_handle = saveCell(file_handle, name, value, input);
        else
            if input.debug_bit
                fprintf('prop: "%s" is a 2D cell array or a 1D cell array longer than %d. Writing data size only. \n', name, input.att_length);
                if iscellstr(value)
                    class_str = 'String Cell';
                else
                    class_str = 'Cell';
                end
                
                saveString(file_handle, name, sprintf('{%s %s}', util.text.print_vec(size(value), 'x'), class_str), input);
                
            end
            
        end
        
    elseif isnumeric(value)
        
        if isempty(value)
            
            if input.debug_bit, disp(['prop: "' name '" is empty. Writing as attribute...']); end
            
            file_handle = saveNumericAtt(file_handle, name, value, input);
            
        elseif isscalar(value)
            
            if input.debug_bit, disp(['prop: "' name '" is scalar. Writing as attribute...']); end
            
            file_handle = saveNumericAtt(file_handle, name, value, input);
            
        elseif isvector(value) && length(value)<=input.att_length
            
            if input.debug_bit, disp(['prop: "' name '" is a vector shorter/equal to ' num2str(input.att_length) '. Writing as attribute...']); end
            
            file_handle = saveNumericAtt(file_handle, name, value, input);
            
        elseif isvector(value) && length(value)>input.att_length
            
            if input.debug_bit
                fprintf('prop: "%s" is a vector longer than %d...', name, input.att_length);
                if util.text.cs(input.format, 'hdf5', 'h5', 'h5z', 'struct', 'cell')
                    fprintf('Writing as dataset to %s\n', util.text.sa(input.location, name));
                elseif util.text.cs(input.format, 'text', 'txt')
                    fprintf('Writing data size only. \n');
                end
            end
            
            file_handle = saveMatrix(file_handle, name, value, input);
            
        else
            
            if input.debug_bit 
                fprintf('prop: "%s" is a matrix... ', name);
                if util.text.cs(input.format, 'hdf5', 'h5', 'h5z', 'struct', 'cell')
                    fprintf('Writing as dataset to %s\n', util.text.sa(input.location, name)); 
                elseif util.text.cs(input.format, 'text', 'txt')
                    fprintf('Writing data size only. \n');
                end
            end
            
            file_handle = saveMatrix(file_handle, name, value, input);
            
        end
        
    elseif isobject(value)
        
        if input.debug_bit, disp(['prop: "' name '" is an object... placing link.']); end
        file_handle = saveObject(file_handle, name, value, input);
        
    end
    
end

function file_handle = saveString(file_handle, name, value, input)
    
    import util.text.cs;
    
    if cs(input.format, 'hdf5', 'h5', 'h5z')
        
        % properties
        acpl = H5P.create('H5P_ATTRIBUTE_CREATE');
        acpl_cleanup = onCleanup(@() H5P.close(acpl));
        
        % data type
        type_id = H5T.copy('H5T_C_S1');
        type_id_cleanup = onCleanup(@() H5T.close(type_id));
        
        if ~isempty(value)
            H5T.set_size(type_id, length(value));            
        end
        
        H5T.set_strpad(type_id, 'H5T_STR_NULLTERM'); % null terminator for strings...
        
        % data space
        if isempty(value)
            space_id = H5S.create('H5S_NULL');
        else
            space_id = H5S.create('H5S_SCALAR');
        end
        
        space_id_cleanup = onCleanup(@() H5S.close(space_id));
        
        % make and fill the attribute
        attr_id = H5A.create(file_handle, name, type_id, space_id, acpl);
        attr_id_cleanup = onCleanup(@() H5A.close(attr_id));
        
        if ~isempty(value)
            H5A.write(attr_id,type_id,value)
        end
        
        % these are replaced by the onCleanup objects...
%         H5A.close(attr_id);
%         H5T.close(type_id);
%         H5P.close(acpl);
        
    elseif cs(input.format, 'text', 'txt')
        fprintf(file_handle, '%25s: %s\n', name, value);  
    elseif cs(input.format, 'struct', 'cell')
        file_handle{end}.(name) = value;
    else
        error(['Unknown file type: ' input.format '... use HDF5 or TEXT.']);
    end
end

function file_handle = saveNumericAtt(file_handle, name, value, input)
    
    import util.text.cs;
    
    if cs(input.format, 'hdf5', 'h5', 'h5z')
        
        % properties
        acpl = H5P.create('H5P_ATTRIBUTE_CREATE');
        acpl_cleanup = onCleanup(@() H5P.close(acpl));
        
        % data type
        if isa(value, 'double')
            type_id = H5T.copy('H5T_NATIVE_DOUBLE');
        elseif isa(value, 'uint16')
            type_id = H5T.copy('H5T_NATIVE_USHORT');
        elseif isa(value, 'single')
            type_id = H5T.copy('H5T_NATIVE_FLOAT');
        else
            error('Unsupported numeric attribute type "%s". Use "double" or "single" or "uint16"', class(value));
        end
        
        type_id_cleanup = onCleanup(@() H5T.close(type_id));
                
        % data space
        if isempty(value)
            space_id = H5S.create('H5S_NULL');
        else
            rank = 1;
            dims = length(value);
            space_id = H5S.create_simple(rank, dims, dims);
        end
        
        space_id_cleanup = onCleanup(@() H5S.close(space_id));
        
        % make and fill the attribute
        attr_id = H5A.create(file_handle, name, type_id, space_id, acpl);
        attr_id_cleanup = onCleanup(@() H5A.close(attr_id));
                
        if ~isempty(value)
            H5A.write(attr_id,type_id,value)
        end

        % these are replaced by onCleanup objects
%         H5A.close(attr_id);
%         H5T.close(type_id);
%         H5P.close(acpl);
        
    elseif cs(input.format, 'text', 'txt')
        if isscalar(value)
            fprintf(file_handle, '%25s: %s\n', name, util.text.print_vec(value));
        else
            fprintf(file_handle, '%25s: [%s]\n', name, util.text.print_vec(value));
        end
    elseif cs(input.format, 'struct', 'cell')
        file_handle{end}.(name) = value;
    else
        error(['Unknown file type: ' input.format '... use HDF5 or TEXT.']);
    end
end

function file_handle = saveMatrix(file_handle, name, value, input)
    
    import util.text.cs;
    
    if cs(input.format, 'hdf5', 'h5', 'h5z')
        
        % properties
        link_create_properties = H5P.create('H5P_LINK_CREATE');
        H5P.set_create_intermediate_group(link_create_properties,1); % I think this allows making all required groups down to the location of this dataset. 
        dataset_create_properties = H5P.create('H5P_DATASET_CREATE');
        link_create_properties_cleanup = onCleanup(@() H5P.close(link_create_properties));
        
        if input.deflate % use chunk ONLY when deflating! 
            
            H5P.set_chunk(dataset_create_properties, fliplr(input.chunk));
            H5P.set_deflate(dataset_create_properties, input.deflate);
            
        end
                
        % data space
        if isempty(value)
            space_id = H5S.create('H5S_NULL');
        else
            rank = ndims(value);
            dims = fliplr(size(value));
            space_id = H5S.create_simple(rank, dims, dims);
        end
        
        space_id_cleanup = onCleanup(@() H5S.close(space_id));
        
        if isa(value, 'double')
            datatype = 'H5T_NATIVE_DOUBLE'; 
        elseif isa(value, 'uint16')
            datatype = 'H5T_NATIVE_USHORT';
        elseif isa(value, 'single')
            datatype = 'H5T_NATIVE_FLOAT';
        else
            error(['unknown datatype: "' class(value) '" use "double" or "uint16"...']);
            % add other types as well...
        end
        
        % make and fill the attribute
        dataset_id = H5D.create(file_handle, util.text.sa(input.location, name), ...
            datatype, space_id, link_create_properties, dataset_create_properties, 'H5P_DEFAULT');
        
        dataset_id_cleanup = onCleanup(@() H5D.close(dataset_id));
        
        if ~isempty(value)
            H5D.write(dataset_id, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', value);
        end
        
        % these are replaced by onCleanup objects...
%         H5D.close(dataset_id);        
%         H5P.close(dataset_create_properties);
%         H5P.close(link_create_properties);
        
    elseif cs(input.format, 'text', 'txt')
        fprintf(file_handle, '%25s: [%s %s]\n', name, util.text.print_vec(size(value), 'x'), class(value));
    elseif cs(input.format, 'struct', 'cell')
        file_handle{end}.(name) = value;
    else
        error(['Unknown file type: ' input.format '... use HDF5 or TEXT.']);
    end
end

function file_handle = saveCell(file_handle, name, value, input)
    
    for ii = 1:length(value)
        try
            file_handle = saveProperty(file_handle, [name '{' num2str(ii) '}'], value{ii}, input);
        catch ME
            error(['Error when saving ' name '{' num2str(ii) '}. ', getReport(ME)]);
        end
    end
    
end

function file_handle = saveObject(file_handle, name, value, input)
    
    import util.text.cs;
    
    size_vec = builtin('size', value);
    
    if prod(size_vec)==0
        file_handle = saveNumericAtt(file_handle, name, [], input); % leave an empty value instead of object...
        return;
    elseif prod(size_vec)==1 
        link_address = checkList(value, input.handle_list);
    else
        link_address = ''; % for obj-vectors we just let "save" break them up into separate objects for us. 
    end
    
    if cs(input.format, 'hdf5', 'h5', 'h5z')
        
        if isa(value, 'datetime')
            saveString(file_handle, name, util.text.time2str(value), input);
        elseif isa(value, 'containers.Map')
            saveCell(file_handle, [name '.keys'], value.keys, input);
            saveCell(file_handle, [name '.values'], value.values, input);
        elseif isa(value, 'table')
            % need to write a HDF5 table...
            fprintf('Writing tables into HDF5 is not yet supported... while trying to write "%s"\n', name);
        else
        
            if isempty(link_address) % check if we need to save a copy of this object

                util.oop.save(value, file_handle, input.output_vars{:}, 'name', name);

                link_address = util.text.sa(input.location, name);

            end

            saveString(file_handle, name, ['--> ' link_address], input); % make sure the object is linked in the conataining object
        
        end
        
    elseif cs(input.format, 'text', 'txt')
        
        if builtin('isempty', value)
            fprintf(file_handle, '%25s: [%s %s]\n', name, util.text.print_vec(size_vec, 'x'), class(value));
        elseif isa(value, 'datetime')
            fprintf(file_handle, '%25s: %s\n', name, util.text.time2str(value));
        elseif isa(value, 'containers.Map')
            saveCell(file_handle, [name '.keys'], value.keys, input);
            saveCell(file_handle, [name '.values'], value.values, input);
        elseif isa(value, 'table')
            fprintf(file_handle, '%25s: [%s %s]\n', name, util.text.print_vec(size_vec, 'x'), class(value));
            rows = 10; 
            if input.table_full, rows = []; end
            fprintf(file_handle, '%s', util.text.print_table(value, 'num_rows', rows, 'indent', 5));
        elseif ~isempty(link_address)
            fprintf(file_handle, '%25s: [%s %s] (link: %s)\n', name, util.text.print_vec(size_vec, 'x'), class(value), link_address); % link back to existing location
        else
            fprintf(file_handle, '%25s: [%s %s]', name, util.text.print_vec(size_vec, 'x'), class(value));        
            if input.recursive && ~builtin('isempty', value)
                fprintf(file_handle, ' (link: %s)\n', util.text.sa(input.location, name)); % give the link to the location to come
            else
                fprintf(file_handle, '\n');
            end
        end
        
    elseif cs(input.format, 'struct', 'cell')
        if builtin('isempty', value)
            str = sprintf('[%s %s]', util.text.print_vec(size_vec, 'x'), class(value));
        elseif isa(value, 'datetime')
            str = sprintf('%s', util.text.time2str(value));
        elseif ~isempty(link_address)
            str = sprintf('[%s %s] (link: %s)', util.text.print_vec(size_vec, 'x'), class(value), link_address); % link back to existing location
        else   
            if input.recursive && ~builtin('isempty', value)
                str = sprintf('[%s %s] (link: %s)', util.text.print_vec(size_vec, 'x'), class(value), util.text.sa(input.location, name)); % give the link to the location to come
            else
                str = sprintf('[%s %s]', util.text.print_vec(size_vec, 'x'), class(value));
            end
        end
        file_handle{end}.(name) = str;
    else
        error(['Unknown file type: ' input.format '... use HDF5 or TEXT.']);
    end
    
end

function val = checkList(obj, list)
% returns the address of the object if it is on the list (else return '')
    
    if isa(obj, 'handle') && ~isempty(obj) % if obj is empty or isn't a handle --> it won't be on the list...

        for ii = 1:length(list)
            if ~isempty(list{ii}) && obj==list{ii}{1}
                val = list{ii}{2};
                return;
            end
        end
        
    end
    
    val = '';
    
end

