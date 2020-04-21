function txt_out = print_table(data, varargin)
% Usage: txt_out = print_table(data, varargin)
% Produce a nicely formatted text from a table, cell array or numeric input. 
%
% Input: a table, cell array, or numeric array. 
%
% Output: either a string with the data formatted to a table, or show it. 
%
% Optional Arguments: 
%   -names: add the column headers if they are not provided in the table. 
%   -indent: add some space at the start of each line. Default 0. 
%   -delim: a string (or single char) to go between columns. Default '|'. 
%           NOTE: to print without delimiter, set it to single space ' '. 
%   -sides: print the delimiter on the left and right of the table. Default true. 
%   -top: print a line on the top and bottom of the table. Default false. 
%   -num_rows: maximum number of rows to show. Default is [] (unlimited). 
%              If the number is exceeded by the input, will stop printing
%              after the number of rows is reached, and adds one final line
%              with ellipses ('...') in each column. 
%              NOTE: when adding ellipses, the bottom line is never drawn. 
%   -precision: how many digits to take when converting numbers to strings. 
%               If given a numeric value, will use that as the number of 
%               significat digits (i.e., num2str(num, precision). 
%               If left empty (default) will just call the default num2str.
%               If given as a string, will be used as a format sepcifier for
%               a call to sprintf, e.g., sprintf('%6.4g', ...). 
%   -tex: format the table to be used in a tex document. 
%         This includes overriding the delimiter to be '&' and sides=false. 
%

    if nargin==0, help('util.text.print_table'); return; end
    
    input = util.text.InputVars;
    input.input_var('names', [], 'headers'); 
    input.input_var('indent', 0);
    input.input_var('delim', []);
    input.input_var('sides', true); 
    input.input_var('top', false); 
    input.input_var('num_rows', []);
    input.input_var('precision', []); 
    input.input_var('tex', false, 'latex'); 
    input.scan_vars(varargin{:});
    
    if ~isnumeric(data) && ~iscell(data) && ~isa(data, 'table')
        error('Can only format data from numeric arrays, cell arrays and tables. Got a "%s" instead. ', class(data)); 
    end
    
    if input.tex
        input.delim = '&';
        input.sides = 0;
    else        
        if isempty(input.delim)
            input.delim = '|';
        end
    end
    
    if isempty(input.names) % if we didn't get the names from the user
        if isa(data, 'table')
            input.names = data.Properties.VariableNames;
        else
            input.names = {};
            for ii = 1:size(data,2)
                input.names{end+1} = sprintf('column %d', ii);
            end
        end
    else % if we do get names, we must check the size matches!
        if ~iscell(input.names) || size(input.names)~=size(data,2)
            error('Must input "names" as a cell array of the same size as the number of columns. Got a %s %s instead', ...
                util.text.print_vec(size(input.names), 'x'), class(input.names));
        end
    end
    
    %%%%%%%%%%%% prepare the data %%%%%%%%%%%%%%%%%%
    
    % make sure the data is stored as a cell array! 
    if isa(data,'table')
        C = table2cell(data);
    elseif isnumeric(data)
        C = num2cell(data);
    end

    % if we use "num_rows" we need to check and truncate the data
    if ~isempty(input.num_rows) && input.num_rows<size(data,1)
        C = C(1:input.num_rows,:);
        C = [C; repmat({'...'}, [1 size(C,2)])];
    end

    C = [input.names; C]; 

    C = format_cell(C, input.precision);
    
    % find how many characters is the width of a whole row
    N = 0; 
    
    for ii = 1:size(C,2)
        N = N + length(C{1,ii}) + 2; 
    end
    
    N = N + (size(C,2)+1).*length(input.delim); % add the delimiters
    
    %%%%%%%%%%% start writing the string %%%%%%%%%%%%
    
    indentation = repmat(' ', [1, input.indent]); % a string with some spaces
    
    txt = ''; % start with an empty output string
    
    if input.top
        txt = sprintf('%s%s%s\n', txt, indentation, printline(N,0,input.tex)); 
    end
    
    txt = sprintf('%s%s%s\n', txt, indentation, printrow(C(1,:), input.delim, input.sides & input.top, input.tex)); % add the column names
    
    txt = sprintf('%s%s%s\n', txt, indentation, printline(N,1,input.tex)); % add a double line
    
    for ii = 2:size(C,1)
        txt = sprintf('%s%s%s\n', txt, indentation, printrow(C(ii,:), input.delim, input.sides, input.tex)); % add the column names
    end

    if input.top && (isempty(input.num_rows) || size(data,1)<=input.num_rows) % no ellipses so we can close the bottom of the table too
        txt = sprintf('%s%s%s\n', txt, indentation, printline(N,0,input.tex)); 
    end
    
    txt = sprintf('\n%s\n', txt);
    
    if nargout>0
        txt_out = txt;
    else
        disp(txt);
    end

end

function C = format_cell(C, prec) % turn each cell into a string

    for ii = 1:size(C,1)
        
        for jj = 1:size(C,2)
            
            val = C{ii,jj};
            
            if isnumeric(val) && isscalar(val)
                if isempty(prec)
                    C{ii,jj} = num2str(val);
                elseif isnumeric(prec)
                    C{ii,jj} = num2str(val, prec);
                elseif ischar(prec)
                    C{ii,jj} = sprintf(prec, val); 
                end
            elseif ischar(val)
                C{ii,jj} = sprintf('%s', val);
            elseif isa(val, 'datetime')
                C{ii,jj} = util.text.time2str(val);
            else
                C{ii,jj} = sprintf('[%s %s]', util.text.print_vec(size(val)), class(val));
            end
            
        end
        
    end
    
    % now find the widest string in each column
     
    widths = max(max(cellfun(@length, C)),4); % minimal width is 4 characters anyway
    
    for ii = 1:size(C,1)
        
        for jj = 1:size(C,2)
            C{ii,jj} = sprintf(['%' num2str(widths(jj)) 's'], C{ii,jj});
        end
        
    end
    

end

function str = printline(N, doubleup, latex) % add a horizontal line (use doubleup to make it two lines, latex will make \hline)
    
    if latex
        if doubleup
            str = '\hline\hline';
        else
            str = '\hline';
        end
    else
        if doubleup
            str = sprintf('%s', repmat('=', [1,N])); 
        else
            str = sprintf('%s', repmat('-', [1,N])); 
        end
    end
    
end

function str = printrow(c, delim, sides, tex) % print the content of cell vector "c" with delimiter "delim"
    
    if sides
        str = delim;
    else
        str = repmat(' ', [1, length(delim)]);
    end
    
    for ii = 1:length(c)
        if ii==length(c)
            str = sprintf('%s %s ', str, c{ii}); 
        else
            str = sprintf('%s %s %s', str, c{ii}, delim); 
        end
    end
    
    if sides
        str = [str delim];
    else
        str = [str repmat(' ', [1, length(delim)])];
    end
    
    if tex
        str = [str '\\'];
    end
    
end
