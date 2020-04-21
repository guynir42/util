classdef CircularBuffer < dynamicprops
% Holds a set number of rows (given as "N") of arbitrary size in 2nd dimension
% (and in higher dimensions if needed). When the number of rows given to the
% buffer exceeds "N" it will just add them at the start of the buffer. 
% This is useful for saving data on the latest few measurements, like a 
% stack with a "first in, first out" rule. 
%
% When constructing the buffer or when using reset, use the optional input
% argument to define "N" (default value is 10). Or set it directly in the 
% object before filling it. 
%
% To add data use input() with a row vector (or a matrix of higher dimensions
% that has a singleton 1st dimesnion). 
% All input matrices must be the same size in all dimension.
% The buffer adds them one after the other in dimension 1. 
% 
% The data can be accessed directly by calling "data" or "data_ordered" 
% that cycles the rows so they are given in the same order they were input. 
% 
% Use "mean", "median" and "var" to get statistics on each column. 
% These values are lazy loaded, and recalculated after adding new data, 
% but only when required by the user. 
%
% You can add a cell array "titles" with the same size as the number of 
% columns in the buffer to make it easier to remember what each column
% represents (like in matlab tables). 


    properties
        
        N = 10; % max number of samples to keep at any time (along 1st dimension)
        idx = 0; % the current index stating the last entry 
        counter = 0; % how many total entries have ever been input since the last reset()
        
        size_vec = []; % specify the size of incoming matrices (they should all be the same size)
        
        titles = {}; % give each column in the data a meaningful name
        
        mean; % of each column, excluding NaNs (lazy loaded)
        median; % of each column, excluding NaNs (lazy loaded)
        var; % of each column, excluding NaNs (lazy loaded)
        
    end
    
    properties(Dependent=true)
        
        Nfilled; % size of useful part of raw_data
        
        data; % all that is stored in the buffer (removing trailing NaNs that have not been filled yet
        data_ordered; % the same data, cycled around so it is given in order it was input
        
    end
        
    properties(Hidden=true)
        
        raw_data = []; % the actual data is saved with NaNs in all the rows that have yet to be filled
        
    end
    
    methods % constructor
        
        function obj = CircularBuffer(varargin) % can give the constructor a new value for "N"
            
            input = util.text.InputVars;
            input.input_var('N', obj.N, 'number', 'length');
            input.use_ordered_numeric = 1;
            input.scan_vars(varargin{:});
            
            obj.N = input.N;
            
        end
    
    end
    
    methods % resetters
        
        function reset(obj, N) % clears the buffer and lets you start again. Can give a new "N" as optional argument
            
            if nargin>1 && ~isempty(N) && isnumeric(N) && N>0
                obj.N = N;
            end
            
            obj.raw_data = [];
            obj.idx = 0;
            obj.counter = 0;
            obj.size_vec = [];
            
        end
        
    end 
    
    methods % getters
        
        function val = dots_cell(obj, num_dims) % make a cell vector with ':' in each cell
            
            val{1} = obj.idx;
            
            if num_dims>1
                [val{2:num_dims}] = deal(':');
            end
                
        end
        
        function val = get.Nfilled(obj) % number of rows in the useful part of the buffer (excluding rows not yet filled)
            
            val = min(obj.counter, obj.N);
            
        end
        
        function val = get.data(obj) % remove the trailing NaN rows that have not been filled yet
            
            if isempty(obj.raw_data)
                val = [];
            else
                vec = obj.dots_cell(length(obj.size_vec));
                vec{1} = 1:min(obj.N, obj.counter);
                val = obj.raw_data(vec{:});
            end
            
        end
        
        function val = get.data_ordered(obj) % cycle the data around the current index so rows are ordered by when they were input to the buffer
            
            if obj.idx<1
                val = [];
                return;
            end
            
            % the following code gives to subsref a 1st dim with the correct 
            % order (start at obj.idx+1, loop back around to obj.idx), and
            % the other dims are just ':', as many as needed...
            idx_end = size(obj.data,1); 
            
            S1 = struct('type', '()', 'subs', obj.idx+1:idx_end); 
            S2 = struct('type', '()', 'subs', 1:obj.idx); 
            
            S1.subs = {S1.subs}; 
            S2.subs = {S2.subs}; 
            
            for ii = 2:ndims(obj.data)
                S1.subs{end+1} = ':';
                S2.subs{end+1} = ':';
            end
            
%             val = vertcat(obj.data(obj.idx:end,:), obj.data(1:obj.idx-1,:));
            val = vertcat(subsref(obj.data, S1), subsref(obj.data, S2));
            
        end
        
        function val = get.mean(obj) % get the nanmean of each coloumn (lazy loaded!)
            
            if isempty(obj.mean)
                obj.mean = nanmean(obj.data, 1);
            end
            
            val = obj.mean;
            
        end
        
        function val = get.median(obj) % get the nanmedian of each column (lazy loaded!)
            
            if isempty(obj.median)
                obj.median = nanmedian(obj.data, 1);
            end
            
            val = obj.median;
            
        end
        
        function val = get.var(obj) % get the nanvar of each column (lazy loaded!)
            
            if isempty(obj.var)
                obj.var = nanvar(obj.data, [], 1);
            end
            
            val = obj.var;
            
        end
        
        function val = is_full(obj) % has the buffer been input enough rows to fill it
            
            val = obj.counter>=obj.N;
            
        end
        
        function val = is_empty(obj) % true if no rows have been input since the last reset()
            
            val = obj.Nfilled==0;
            
        end
        
        function str_out = printout(obj) % print to string or terminal a summary of the data
            
            str = '';
            
            if ~isempty(obj.titles)
                
                for ii = 1:length(obj.titles)
                    str = [str sprintf('% 12s ', obj.titles{ii})];
                end
                
                str = [str '\n'];
                
            end
            
            for ii = 1:size(obj.data, 1)
                
                for jj = 1:size(obj.data,2)
                
                    str = [str sprintf('% 12.10g ', obj.data(ii,jj))];
                    
                end
                
                str = [str '\n'];
                
            end
            
            fprintf(str);
            
            if nargout>0
                str_out = str;
            else
                disp(str);
            end
            
        end
        
    end 
    
    methods % setters
       
        function set.raw_data(obj, val) % resets the values stored in "mean", "median" and "var"
            
            obj.mean = [];
            obj.median = [];
            obj.var = [];
            
            obj.raw_data = val;
            
        end
        
    end
    
    methods % calculations
        
        function input(obj, matrix) % insert a matrix with singleton 1st dim in the next row of the buffer (all input matrices must have the same dimensions)
        
            if size(matrix,1)>1
                error('Must give a matrix with scalar first dimension. Instead got size(matrix)= %s', util.text.print_vec(size(matrix)));
            end
            
            if ~isempty(obj.size_vec) && length(obj.size_vec)>1
                if length(obj.size_vec)~=ndims(matrix)
                    error('Must input a matrix with %d dimensions...', length(obj.size_vec));
                end
                
                s = size(matrix);
                if any(obj.size_vec(2:end)~=s(2:end))
                    error('Size mismatch: size(data)= %s, size(matrix)= %s', ...
                        util.text.print_vec(obj.size_vec, 'x'), util.text.print_vec(size(matrix),'x'));
                end
                
            end
            
            if isempty(obj.raw_data)
            
                d = ndims(matrix); % number of dimensions of input matrix 
                vec = [obj.N ones(1,d-1)];
                obj.raw_data = repmat(matrix, vec);
                obj.idx = 1;
                obj.counter = 1;
                obj.size_vec = size(matrix);
                obj.size_vec(1) = obj.N;
                
            else
                
                obj.idx = obj.idx + 1;
                if obj.idx>obj.N
                    obj.idx = 1;
                end
                obj.counter = obj.counter + 1;
                vec = obj.dots_cell(ndims(matrix));
                obj.raw_data(vec{:}) = matrix;
                
            end
            
        end
        
    end
    
end