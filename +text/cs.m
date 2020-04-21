function val = cs(str, varargin)
% Usage: val = cs(str, varargin)
% Compare "str" to several optional strings, with loose matching conditions. 
% This is useful for checking user input (e.g., varargin pairs) where the 
% use can be lazy by not using capital letters, spaces or underscores, 
% and only write the first few letters of the parameter name. 
% 
% Multiple match options are tested, if any of them match, returns true. 
% Test strings can be given as a cell array of strings or as individual 
% arguments to the function: 
%   -cs('foo', 'bar', 'baz')
%   -cs('foo', {'bar', 'baz'})
%
% Removes spaces and underscores before comparing. Ignores case. 
% 
% Examples (all these are true):
%   -cs('Use_plot', 'use plot')
%   -cs('USEPLOT', 'use_plot')
%   -cs('use plot', 'USEPLOT')
%
% Doesn't match the whole word, only the initial letters. 
% if any argument is numeric, it is used as the minimal number of letters
% needed to compare the string. If none is given (or zero) then the number
% of letters in "str" is used. 
%
% Example: cs('font', 'font_size') returns true
% Example: cs('font', 'font_size', 6) returns false
% This is useful when several parameters have the same starting characters. 

    if nargin==0
        help('util.text.cs');
        return;
    end
    
    val = 0;

    if ~ischar(str)
        return;
    end

    cell_array = {};
    num_letters = [];

    for ii = 1:length(varargin) % make sure all values are in one, continuous cell

        if iscell(varargin{ii})
            cell_array = [cell_array, varargin{ii}{:}];
        elseif ischar(varargin{ii}) || isnumeric(varargin{ii})
            cell_array = [cell_array, varargin{ii}];        
        end

    end

    if isempty(str) && iscell(cell_array) && ~any(cellfun(@isempty, cell_array)) % if str is empty and any of the varargin inputs are not empty! 
        return;
    end

    idx_num = find(~cellfun(@ischar, cell_array));
    if ~isempty(idx_num)
        num_letters = cell_array{idx_num(end)};
        cell_array(idx_num) = [];
    end
    
    if isempty(str) &&  ~isempty(cell_array)
        return;
    end

    str = strrep(str, '_','');
    str = strrep(str, ' ','');

    if iscell(cell_array)
        for ii = 1:length(cell_array)
            cell_array{ii} = strrep(cell_array{ii}, '_','');
            cell_array{ii} = strrep(cell_array{ii}, ' ','');
        end
    else
        cell_array = strrep(cell_array,'_','');    
        cell_array = strrep(cell_array,' ','');
    end

    if isempty(num_letters) || num_letters==0
        num_letters = length(str);
    end

    val = any(strncmpi(str, cell_array, num_letters));

end