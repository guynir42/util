classdef WorkingDirectory < handle
% Keeps track of a directory in the filesystem. 
% Used as a bookmark that is a little like the matlab working directory, 
% only you can keep many different places in the filesystem. 
% 
% You can change dir using cd(), browse() to choose a folder from the system
% dialog, and match() to do glob matching. 
% 
% The constructor can take no arguments (use current working directory) or
% take another WorkingDirectory object, or take a string with the location 
% of the target directory in the file system. 
% 
% Use cd() like normal change directory, including '..' to go up one level. 
%
% Use back() to go back to the previous folder. 
%
% Use match(...) to get all the files that fit the given glob in the current
% directory pointed to by the object. 
%
% Use browse() to change to a folder using a graphic interface. 
%
% 
%
% Examples: d=util.sys.WorkingDirectory; d.cd('..'); d.match('*.m'); d.pwd

    properties
    
        cwd; % current working directory! 
        
    end
    
    properties(Hidden=true)
       
        prev_dir; % to let the user do back()
        
    end
    
    events
       
        directory_changed;
        
    end
    
    methods % constructor 
       
        function obj = WorkingDirectory(start_at) % give starting folder as string or another such object (default is current dir)
            
            if nargin==0 || isempty(start_at)
                obj.cwd = pwd;
            else
                if isa(start_at, 'util.sys.WorkingDirectory')
                    obj.cwd = start_at.cwd;
                elseif ischar(start_at)
                    obj.cwd = start_at;
                else
                    error('input a string or WorkingDirectory object as input to constructor');
                end
            end
            
        end
        
    end
       
    methods % getters
    
        function d = get.cwd(obj) % always give back the current working directory without a trailing '/'
            
            if strcmp(obj.cwd(end),'/') || strcmp(obj.cwd(end),'/')
                d = obj.cwd;
            elseif strcmp(obj.cwd,'.') || strcmp(obj.cwd, './')
                d = pwd;
            else
                d = [obj.cwd '/'];
            end
            
        end
                  
        function list = ls(obj, directory) % list all files and folders in the directory (optional argument to list another directory in absolute/relative path)
            
            if nargin<2 || isempty(directory)
                directory = obj.cwd;
            end
            
            directory = obj.check_dir(directory);
            
            if nargout==0
                ls(directory);
            else
                list = dir(directory);
                list = {list.name}';
            end
                        
        end
        
        function lh(obj, directory) % list the files and folder with last modification date and size (for files) in human readable format
            
            if nargin<2 || isempty(directory)
                directory = obj.cwd;
            end
            
            directory = obj.check_dir(directory);
            
            d = dir(directory);
            
            for ii = 1:length(d)
               
                if ~strcmp(d(ii).name,'.') && ~strcmp(d(ii).name,'..')
                    
                    if d(ii).isdir
                        fprintf('%-60s %-20s \n', d(ii).name, datestr(d(ii).datenum));
                    elseif d(ii).bytes>1024^3
                        fprintf('%-60s %-20s      %6.2f Gbs\n', d(ii).name, datestr(d(ii).datenum), d(ii).bytes/1024^3);
                    elseif d(ii).bytes>1024^2
                        fprintf('%-60s %-20s      %6.2f Mbs\n', d(ii).name, datestr(d(ii).datenum), d(ii).bytes/1024^2);
                    elseif d(ii).bytes>1024
                        fprintf('%-60s %-20s      %6.2f kbs\n', d(ii).name, datestr(d(ii).datenum), d(ii).bytes/1024^1);
                    else
                        fprintf('%-60s %-20s      % 6d bytes\n', d(ii).name, datestr(d(ii).datenum), d(ii).bytes);
                    end
                end
                
            end
                        
        end
        
        function DN_out = dir(obj, directory, use_fullpath) % return a cell array with all subfolders in "directory". "use_fullpath" specificies the path to each file
            
            if nargin<2 || isempty(directory)
                directory = obj.cwd;
            end
            
            if nargin<3 || isempty(use_fullpath)
                use_fullpath = 0;
            end
            
            directory = obj.check_dir(directory);
  
            DN = obj.dir_private(directory, use_fullpath);
            
            if nargout==0
                disp(DN);
            else
                DN_out = DN;
            end
            
        end
        
        function DN = dir_private(obj, directory, use_fullpath) % not sure why this is needed in addition to dir()
                        
            if nargin<2 || isempty(directory)
                directory = obj.cwd;
            end
            
            if nargin<3 || isempty(use_fullpath)
                use_fullpath = 0;
            end
            
            list = dir(directory);
            N = {list.name}';
            D = [list.isdir]';
            P = {list.folder}';
            DN = {}; % directory names
            
            for ii = 1:length(N)
                
                if D(ii)==1 && ~strcmp(N{ii}, '.') && ~strcmp(N{ii}, '..')
                    if use_fullpath
                        DN{end+1} = fullfile(P{ii}, N{ii});
                    else
                        DN{end+1} = N{ii};
                    end
                end
                
            end
            
            DN = DN';
            
        end
        
        function list = match(obj, expr, directory) % use glob matching on all files in "directory" (default is cwd)
            
            if nargin<2 
                expr = '';
            end
            
            if nargin<3 || isempty(directory)
                directory = obj.cwd;
            end
                        
            directory = obj.check_dir(directory);
            
            assert(~isempty(directory), ['no such directory: ' directory]);
            
            list = dir(util.text.sa(directory, expr));
            folders = {list.folder}';
            names = {list.name}';
            idx = ~[list.isdir]';
            
            list = strcat(folders(idx), '/', names(idx));
            
        end
        
        function list = match_folders(obj, expr, directory) % same as match() only it looks at folders only
            
            if nargin<2 
                expr = '';
            end
            
            if nargin<3 || isempty(directory)
                directory = obj.cwd;
            end
                        
            directory = obj.check_dir(directory);
            
            assert(~isempty(directory), ['no such directory: ' directory]);
            
            list = dir(util.text.sa(directory, expr));
            folders = {list.folder}';
            names = {list.name}';
            idx = [list.isdir]';
            
            list = strcat(folders(idx), '/', names(idx));
            
        end
        
        function list = regexp(obj, expr, directory, files_or_dirs) % search files in "directory" (default is cwd) using regular expressions. "files_or_dirs" specifies what to search (default is files only)
            
            if nargin<2 
                expr = '';
            end
            
            if nargin<3 || isempty(directory)
                directory = obj.cwd;
            end
                   
            if nargin<4 || isempty(files_or_dirs)
                files_or_dirs = '';
            end
            
            directory = obj.check_dir(directory);
            
            assert(~isempty(directory), ['no such directory: ' directory]);
            
            list = dir(directory);
            folders = {list.folder}';
            names = {list.name}';
            idx = ~cellfun(@isempty, regexp(names, expr)); 
            
            if ~isempty(files_or_dirs) && util.text.cs(files_or_dirs, 'files')
                idx = idx & ~[list.isdir]';
            elseif ~isempty(files_or_dirs) && util.text.cs(files_or_dirs, 'dirs', 'directories', 'folders')
                idx = idx & [list.isdir]';
            end
            
            list = strcat(folders(idx), '/', names(idx));
            
        end
        
        function list = files(obj, directory, use_fullpath) % output all files in "directory" (default is cwd). "use_fullpath" to append the path to each file
                        
            if nargin<2 || isempty(directory)
                directory = obj.cwd;
            end
            
            if nargin<3 || isempty(use_fullpath)
                use_fullpath = 0;
            end
            
            directory = obj.check_dir(directory);
  
            assert(~isempty(directory), ['no such directory: ' directory]); 
            
            FL = obj.files_private(directory, use_fullpath);
            
            if nargout==0
                disp(FL);
            else
                list = FL;
            end
            
        end
        
%         function list = fullnames(obj, directory) % to be depricated! 
%             
%             list = obj.files;
%             
%             for ii = 1:length(list)
%                 list{ii} = [obj.cwd list{ii}];
%             end
%             
%         end
        
        function FL = files_private(obj, directory, use_fullpath) % not sure why we need this in addition to files()
                        
            if nargin<2 || isempty(directory)
                directory = obj.cwd;
            end
            
            if nargin<3 || isempty(use_fullpath)
                use_fullpath = 0;
            end
            
            list = dir(directory);
            N = {list.name}';
            D = [list.isdir]';
            P = {list.folder}';
            FL = {}; % file list
            
            for ii = 1:length(N)
                
                if D(ii)==0 && ~strcmp(N{ii}, '.') && ~strcmp(N{ii}, '..')
                    if use_fullpath
                        FL{end+1} = fullfile(P{ii}, N{ii});
                    else
                        FL{end+1} = N{ii};
                    end
                end
                
            end
            
            FL = FL';
            
        end
        
        function list = walk(obj, directory) % return a list starting with "directory" (default is cwd) with all subfolders added recursively
            
            if nargin<2 || isempty(directory)
                directory = obj.cwd;
            end
            
            list{1} = directory;
            
            subfolders = obj.dir(directory, 1);
            
            for ii = 1:length(subfolders)
                list = [list; obj.walk(subfolders{ii})];
            end
            
        end
        
        function d = pwd(obj) % same as cwd (current working directory) only with '/' appended in the end
            
            d = obj.cwd;
            
            if length(d)>1 && strcmp(d(end), '/')
                d = d(1:end-1);
            end
            
        end
        
        function d = tail(obj) % print the last folder from the cwd full path
            
            [~, d] = fileparts(obj.pwd);
            
        end
        
        function d = two_tail(obj) % print the last two folders of the full path (with '/' between)
            
            [a, b] = fileparts(obj.pwd);
            
            [~, c] = fileparts(a);
            
            d = fullfile(c,b);
            
        end
    end
    
    methods % changing directory
             
        function dir = browse(obj) % load the system GUI for picking a folder, then change to that folder
           
            dir = uigetdir(obj.pwd);
            
            if ~isempty(dir) && ~isnumeric(dir)
                obj.cd(dir);
            end
            
        end
        
        function CWD = check_dir(obj, next_dir, CWD) % check if a directory "next_dir" exists, by absolute path or relative to input CWD (default is object's cwd)
                        
            if nargin<3 || isempty(CWD)
                CWD = obj.cwd;
            end

            if isnumeric(next_dir)
                
                DN = obj.dir_private(CWD);
                
                if next_dir<=length(DN)
                    CWD = [CWD DN{next_dir}];
                    return;
                else
                    CWD = '';
                    return;
%                     error(['current directory ' CWD ' has only ' num2str(length(DN)) ' subdirectories']);
                end
                
            end
            
%             if ~strcmp(next_dir(end), '/')
%                 next_dir = [next_dir '/'];
%             end
            
            % if absolute path is used, it is easy...
            if strcmp(next_dir(1),'/') || ~isempty(regexp(next_dir, '^[A-Z]:', 'once'))
                if exist(next_dir,'dir')
                    CWD = next_dir;
                    return;
                else
                    CWD = '';
                    return;
%                     error(['no such directory: ' next_dir]);
                end
            end
            
            % check if "next_dir" is composite
            ind = strfind(next_dir(1:end-1), '/');
            if ~isempty(ind)
                first_dir = next_dir(1:ind);
                second_dir = next_dir(ind+1:end);
            else
                first_dir = next_dir;
                second_dir = '';
            end
            
            if strcmp(first_dir, '..') || strcmp(first_dir, '../') % if the first part is "up"
            
                CWD = [fileparts(CWD(1:end-1)) '/']; % go up one level in CWD
                
                if isempty(CWD)
                    error('cannot go up from here...');
                end
               
            elseif strcmp(first_dir,'.')
                CWD = pwd;
            else % if the first part is going down the tree
                
                DN = obj.dir_private(CWD);
                
                found = '';
                                
                for ii = 1:length(DN)
                    if strcmp(DN{ii}, first_dir)
                        found = first_dir;
                        break;
                    end
                end % for ii
                
                if isempty(found)
%                     error(['no such directory: ' CWD first_dir]);
                    CWD = '';
                else
                    CWD = [CWD found];
                end
            end
            
            % now we successfully moved to "first_dir"
            if isempty(second_dir)
                return;
            else
                CWD = obj.check_dir(second_dir, CWD);
                return;
            end
            
        end

        function success = cd(obj, move_to) % change directory. Outputs failure if no such folder can be found
            
            if isempty(move_to)
                success = 0;
                return;
            end
            
            if isa(move_to, 'util.sys.WorkingDirectory')
                move_to = move_to.pwd;
            end
            
            temp_cwd = obj.check_dir(move_to);
            
            if ~isempty(temp_cwd)
                obj.prev_dir = obj.cwd;
                obj.cwd = temp_cwd;
                
                notify(obj, 'directory_changed');
                
                if nargout>0, success = 1; end
                
            else
                warning(['cannot find directory: ' move_to]);
                
                if nargout>0, success = 0; end
                    
            end
            
        end
        
        function success = smart_cd(obj, str, CWD) % same as cd(), only it changes to the first folder that contains expression "str" (change dir from CWD, defaulting to object's cwd)
           
            success = 0;
            
            if nargin<3 || isempty(CWD)
                CWD = obj.cwd;
            else
                temp_dir = obj.check_dir(CWD);
                if isempty(CWD)
                    error(['cannot find dir ' CWD]);
                else
                    CWD = temp_dir;
                end
            end
            
            D = obj.dir(CWD);
            
            if exist(fullfile(CWD, str), 'dir')
                obj.cd(fullfile(CWD, str))
                success = 1;
            else
                
                fnd = [];
                
                for ii = 1:length(D)
                    
                    fnd = strfind(D{ii}, str);
                    
                    if ~isempty(fnd)
                        obj.cd(fullfile(CWD, D{ii}));
                        success = 1;
                        return;
                    end
                    
                end
                
                if isempty(fnd)
                    disp(['Cannot find expression "' str '" in subdirectories of ' CWD]);
                end
            
            end
            
        end
        
        function here(obj) % change the OBJECT directory to matlab's current working dir
           
            obj.cwd = pwd;
            
        end
                
        function there(obj) % change matlab's current working dir to the OBJECT cwd
            
            cd(obj.cwd);
            
        end
    
        function up(obj) % go up one folder, equivalent to cd('..')
           
            obj.cd('..');
            
        end
        
        function back(obj) % return to the last folder this object pointed to before the latest cd() 
           
            if isempty(obj.prev_dir)
                return;
            end
            
            obj.cd(obj.prev_dir);
            
        end
        
    end
     
    methods % display
        
%         function disp(obj) % override the built-in disp() function to display these objects like folders
%             
%             if isempty(obj)
%                 builtin('disp', obj);
%             else
%                 display(['    CWD: ' obj.cwd]);
%             end
%             
%         end
                
    end
    
end
    