function [Tnew, edges] = bin_table(T, edges, varargin)
% Usage: [Tnew, edges] = bin_table(T, edges, column_number=1, varargin)
% Collects all entries from the chosen column (default is first one), that 
% lie between two adjacent edges into one cell of a new table. 
% The remaining columns of the table are combined according to the choise 
% of the optional argument "function". 
%
% The "edges" input can be a numeric scalar to specify how many (equally
% spaced) bins are required. 
% 
% OPTIONAL ARGUMENTS:
%   -column: what column to use to bunch the table (default 1). 
%   -function: what to do with the remaining columns. By default the function
%              collects them into a cell array. 
%              If "function" is specified, it is used to combine the contents
%              e.g., function=mean will calculate the mean value of all the 
%              elements in each column that are included in each bin. 

    if nargin==0, help('util.vec.bin_table'); return; end
    
    if isempty(T)
        Tnew = T;
        return;
    end
    
    if nargin<2 || isempty(edges)
        edges = ceil(sqrt(height(T)));
    end
    
    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('column', 1);
    input.input_var('function', []);
    input.scan_vars(varargin{:});
    
    if isnumeric(edges) && isscalar(edges)
        edges = linspace(min(T{:,input.column}), max(T{:,input.column}), edges); % treat edges as the number of bins, and use uniform edges in between
        edges = [edges 2*edges(end)-edges(end-1)]; % add another edge for the end
    elseif ischar(edges)
        error('No options are available for "edges" input right now...');
    end
    
    y = discretize(T{:,input.column}, edges);
    
    if isempty(input.function) % just put the collected variables in a cell 
    
        Tnew = cell2table(cell(length(edges)-1,width(T)), 'VariableNames', T.Properties.VariableNames);
    
        for ii = 1:length(edges)-1
            for jj = 1:width(T)
                Tnew{ii,jj} = {T{y==ii, jj}};
            end
        end

    else
        
        Tnew = array2table(NaN(length(edges)-1, width(T)), 'VariableNames', T.Properties.VariableNames);
        
        for ii = 1:length(edges)-1
            for jj = 1:width(T)
                Tnew{ii,jj} = input.function(T{y==ii, jj});
            end
        end
        
    end
    
end