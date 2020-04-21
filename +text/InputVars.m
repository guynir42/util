classdef InputVars < dynamicprops
% Small class that takes input variable names, default values and aliases
% and then scans a list of keyword-arguments and sets the internal data. 
%
% Lets you define optional arguments and scan varargin pairs easily. 
% Start by generating an input object at the entrance to a function. 
% >> input = util.text.InputVars; 
%
% Then add parameters using input_var(keyword, def_value, alias1, alias2,...):
% >> input.input_var('data'); 
% >> input.input_var('size', [10 12]); 
% >> input.input_var('axis', [], 'axes');
%
% The default value is [] unless specified otherwise, for each keyword. 
% The remaining variables are other strings used as comparisons. 
% If any of the alias strings is numeric it specifies how many letters are
% needed to match to the different keywords. 
% The first argument (keyword) and all the aliases are passed as arguments
% to the util.text.cs() function, along with an optional numeric value for
% the minimal number of letters. See the documentation of util.text.cs(). 
%
% After defining the keywords, use scan_vars to parse the varargin pairs:
% >> input.scan_vars(varargin{:}); 
% 
% Keyword-value pairs are parsed using util.text.cs() and each match replaces
% the default value of this object with the varargin value. 
% 
% To use these scanned/default values, just call them as properties of the 
% InputVars object:
% >> Z = zeros(input.size); % use the default size or the size given by user
%
% If many/all the inputs are numeric and have a preferred order, you can allow
% the user to input only the values without text keywords. 
% To do this, set "use_ordered_numeric" to true (default is false). 
% In this case the order of calls to input_var() determine the expected order. 
% Example, assuming flux, error and times are defined in order in func():
% >> func('flux', [10 12 9], 'error', [0.1 0.2 0.3], 'times', [0.1 0.2 0.3])
% >> func([10 12 9], [0.1 0.2 0.3], [0.1 0.2 0.3])
% These two calls are equivalent when "use_ordered_numeric" is true.  
% 

    properties
        
        alias_dictionary; % keep track of the names of each of the parameters
        logical_dictionary; % keep track which parameter is logical (use parse_bool to scan inputs)
        number_dictionary; % keep track of the minimal number of letters required for util.text.cs to match
        
        use_ordered_numeric = 0; % if true, will accept numeric variables in order without keywords
        list_added_properties = {}; % a list of keywords, in the order added when defining the object
        list_scan_properties = {}; % a list of keywords in the order they are given by the varargin pairs
        
    end
    
    methods % constructor
        
        function obj = InputVars(varargin)
            
            obj.alias_dictionary = containers.Map;
            obj.logical_dictionary = containers.Map;
            obj.number_dictionary = containers.Map;
            
        end
        
    end
    
    methods % input and scan
        
        function input_var(obj, name, default_value, varargin) % add keyword with default value and aliases
        % Usage: obj.input_var(name, default_value, varargin)
        % Add a keyword to the list of keyword-value pairs. 
        % 
        % OPTIONAL_ARGUMENTS: use to add aliases to the parameter name. 
        % Can also add a numeric value: the minimal number of characters 
        % needed to match the keyword. 
        
            if nargin<2
                help('util.text.InputVars.input_var');
                return;
            end
            
            name = strrep(name, ' ', '_');
            
            if any(strcmp(name, {'alias_dictionary', 'logical_dictionary', 'number_dictionary', ...
                    'use_ordered_numeric', 'list_added_properties', 'list_scan_properties'}))
                error('Cannot have a new property called "%s", it already exists in the class!', name);
            end
            
            if obj.alias_dictionary.isKey(name)
                error(['the "' name '" parameter is already in the "InputVar" object']);
            end
            
            addprop(obj, name);
            obj.list_added_properties{end+1} = name;
            
            if nargin>2
                obj.(name) = default_value;
                if isa(default_value, 'logical')
                    obj.logical_dictionary(name) = 1;
                else
                    obj.logical_dictionary(name) = 0;
                end
            end
            
            if nargin<4 || isempty(varargin)
                obj.alias_dictionary(name) = {};
                obj.number_dictionary(name) = []; % no restriction on the number of letters required for a match
            else
                
                idx_num = find(~cellfun(@ischar, varargin));
                
                if isempty(idx_num)
                    obj.number_dictionary(name) = []; % no restriction on the number of letters required for a match
                else
                    obj.number_dictionary(name) = varargin{idx_num(end)}; % keep track of how many characters we need for cs to match
                    varargin(idx_num) = []; % get rid of numeric values
                end
                
                obj.alias_dictionary(name) = varargin;
                
            end
            
        end
        
        function scan_vars(obj, varargin) % scan the varargin
            
            if length(varargin)==1 && iscell(varargin{1})
                varargin = varargin{1};
            end
            
            if obj.use_ordered_numeric % assume first few inputs are ordered+numeric (stop when hitting a non-numeric)
                
                counter = 1;
                for ii = 1:min(length(obj.list_added_properties), length(varargin))
                    if ~ischar(varargin{ii})
                        obj.(obj.list_added_properties{ii}) = varargin{ii};
                        obj.list_scan_properties{end+1} = obj.list_added_properties{ii};
                        counter = counter + 1;
                    else
                        break;
                    end
                end
                
                varargin = varargin(counter:end);
                
            end
            
            if ~isempty(varargin) && mod(length(varargin),2)==1
                varargin{end+1} = 1; % positive approach
            end
            
            all_keys = obj.alias_dictionary.keys; % every parameter on the list 
            
            for ii = 1:2:length(varargin)
                
                key = varargin{ii};
                val = varargin{ii+1};
                
                if isnumeric(key)
                    error(['Input keyword-value pair is broken. Expected string but got ' num2str(key(1:10)) ' instead'])
                elseif ~ischar(key)
                    error(['Input keyword-value pair is broken. Expected string but got ' class(key) ' instead'])
                end
                
                if util.text.cs(key, 'print') && ischar(val) && util.text.cs(val, 'pars', 'parameters')
                    obj.printout;
                    return;
                end
                
                for jj = 1:obj.alias_dictionary.length % go over all parameters
                    
                    if util.text.cs(key, [all_keys{jj}, obj.alias_dictionary(all_keys{jj}), obj.number_dictionary(all_keys{jj})])
                        if obj.logical_dictionary(all_keys{jj})
                            obj.(all_keys{jj}) = util.text.parse_bool(val);
                        else
                            obj.(all_keys{jj}) = val;
                        end
                        obj.list_scan_properties{end+1} = all_keys{jj};
                    end
                end
                
            end
            
        end
        
        function scan_obj(obj, other) % take any fields/properties from "other" that match variables in "obj" and use them as defaults
            
            if ~isobject(other) && ~isstruct(other)
                error('Cannot scan a %s type object. Must supply an object or struct', class(other));
            end
            
            if isobject(other)
                list = properties(other);
            elseif isstruct(other)
                list = fields(others);
            end
            
            all_keys = obj.alias_dictionary.keys;
            
            for ii = 1:length(all_keys)
                
                idx = find(strcmp(all_keys{ii}, list), 1, 'first');
                
                if ~isempty(idx)
                    
                    name = list{idx};
                    
                    obj.(name) = other.(name);
                    
                end
                
                
            end
            
        end
        
        function printout(obj) % show the keywords and the current values
            
            keys = obj.alias_dictionary.keys;
            vals = obj.alias_dictionary.values;
            
            fprintf('PARAMETERS (key = val [aliases,...])\n');
            fprintf('------------------------------------\n');
            
            for ii = 1:length(keys)
                
                fprintf('%15s', keys{ii});
                if isprop(obj, keys{ii})
                    if isnumeric(obj.(keys{ii})) 
                        fprintf(' = %f', obj.(keys{ii}));
                    elseif ischar(obj.(keys{ii}))
                        fprintf(' = "%s"', obj.(keys{ii}));
                    elseif islogical(obj.(keys{ii}))
                        fprintf(' = %d', obj.(keys{ii}));
                    end
                end
                
                if ~isempty(vals{ii})
                    fprintf(' [%s]', strjoin(vals{ii}, ', '));
                end
                
                if ~isempty(obj.number_dictionary(keys{ii}))
                    fprintf(' (match number= %d)', obj.number_dictionary(keys{ii}));
                end
                
                fprintf('\n');
                
            end
            
        end
        
        function vars = output_vars(obj) % make a cell array with varargin pairs as they are parsed (to pass to other functions)
            
            keys = obj.alias_dictionary.keys;
            
            vars = {};
            jj = 1;
            
            for ii = 1:length(keys)
                
                vars{jj} = keys{ii};
                vars{jj+1} = obj.(keys{ii});
                jj = jj + 2;
                
            end
            
        end
        
        
    end
    
    methods % default setups
       
        function setupDataInput(obj)
            
            list = properties(file.AstroData);
            
            for ii = 1:length(list)
                obj.input_var(list{ii}, []);
            end

            obj.use_ordered_numeric = 1;
            
            % make sure there are no ambiguities in the name matching
            obj.number_dictionary('cutouts') = 8;
            obj.number_dictionary('cutouts_bg') = 8;
            obj.number_dictionary('positions') = 10;
            obj.number_dictionary('positions_bg') = 10;            
            obj.number_dictionary('t_end') = 6;
            obj.number_dictionary('t_end_stamp') = 6;
            
        end
        
    end
    
    methods(Static=true)
        
        function idx = isInputVars(array) % returns a logical vector the length of "array", with 1s where there is an object of this type
            
            if isempty(array)
                idx = [];
            elseif iscell(array)
                func = @(c) isa(c, 'util.text.InputVars');
                idx = cellfun(func, array);
            else
                idx = isa(array, 'util.text.InputVars');
            end
            
        end
        
    end
    
end



