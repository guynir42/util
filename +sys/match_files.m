function files = match_files(expr, directory, full_path)
% Usage: files = match_files(expr, directory='', full_path=0)
% Match the glob expression "expr" in "directory" (default is empty, i.e.,
% the current dir). Set "full_path" to true to output the list of files with 
% full paths to each file. 
%
% Returns a cell array with all matched files. 

    if nargin==0, help('util.sys.match_files'); return; end

    if nargin<2 || isempty(directory)
        directory = '';
    end
    
    if nargin<3 || isempty(full_path)
        full_path = 0;
    end
    
    list = dir(fullfile(directory, expr));
    folders = {list.folder}';
    names = {list.name}';
    idx = ~[list.isdir]';
    
    if full_path
        files = strcat(folders(idx), '/', names(idx));
    else
        files = names(idx);
    end
    
end