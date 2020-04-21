classdef Logger < handle
% Updates text file with logging user commands and errors.
%
% Constructor can be called with single text argument to set <name>. 
%
% Use obj.input(text, errflag=0) to input normal operation logs, that will
% be saved to file, with timestamp automatically appended. 
% 
% Use obj.error(text) to produce an error log. This error is saved with a 
% timestamp and also a header showing the error. It will optionally also be
% saved to a separate error file. 
%
% Use obj.heartbeat(time_sec, owner) to make the logger check if its owner 
% is still working, and add a line in the logfile to that effect. 
% For checking to work, "owner" must implement "update" method and "status"
% property. Without this (or with empty "owner") logger will just write a 
% line with time: "heartbeat" and nothing more. 
%
% Will generate a new file every day (day starts at 12:00 UTC). 
%
% Filename will be <base_dir>/YYYY-MM-DD_<name> where properties are:
%   *name: the name of hardware/component/sensor (e.g., "mount")
%   *base_dir: the folder where all logfiles are kept. 
%    If left empty, will write to fullfile(getenv('DATA'),'WFAST/logfiles')
%   *use_error_file: if true, will write errors to main file and to 
%    additional error file with same name, appended with _ERROR. 
%
% EXAMPLE: 
% L = util.sys.Logger('mount-ASA'); 
% L.input('Connecting to mount');  % create logfile at C:\Dropbox\data\WFAST\logfiles 
%                                  % with name 2019-04-29_mount-ASA.txt
%                                  % with text: 15:27:34.123 Connecting to mount
% L.error('Mount not responding'); % write this error message, with timestamp
%                                  % and error banner to same file, and also
%                                  % (optionally) to logfile 2019-04-29_mount-ASA_ERROR.txt
% L.base_dir = 'D:\logifles';      % will overwrite the environmental variable 'DATA' 
%
%
    
    properties(Transient=true)
        
        timer;
        
    end
    
    properties % objects
        
        owner; % object that holds this logger
        hndl; % file handle (using fopen)
        hndl_err; % secondary handle to additional log file (errors only)
        time; % datetime object
        
    end
    
    properties % inputs/outputs
        
        report; % combination of datestr+message, that is written to file. 
        
    end
    
    properties % switches/controls
        
        dev_name = 'log'; % name of device/sensor generating the log (e.g., "mount")
        base_dir = ''; % default is fullfile(getenv('DATA'), 'WFAST/logfiles')
        filename = ''; % file name of log file (e.g., 2019-04-29_mount_ASA.txt)
        use_date_dir = true; % if true (default) will put logfile in folder with YYYY-MM-DD format. 
        use_error_file = 0; % to keep an extra file for errors only
        
        debug_bit = 1;
        
    end
    
    properties(Dependent=true)
        
        fullname; % full path to text file (<basedir>/<filename>)
        
    end
    
    properties(Hidden=true)
       
        version = 1.02;
        
    end
    
    methods % constructor
        
        function obj = Logger(varargin)
            
            if ~isempty(varargin) && isa(varargin{1}, 'util.sys.Logger')
                if obj.debug_bit
                    fprintf('Logger copy-constructor v%4.2f\n', obj.version);
                end
                obj = util.oop.full_copy(varargin{1});
                
            elseif ~isempty(varargin) 
                
                for ii = 1:length(varargin)
                
                    if ischar(varargin{ii})
                        obj.dev_name = varargin{ii};
                    elseif isobject(varargin{ii})
                        obj.owner = varargin{ii};
                    end

                    if isempty(obj.dev_name) && ~isempty(obj.owner) && isobject(obj.owner)
                        obj.dev_name = class(obj.owner);
                    end
                
                end
                
                if obj.debug_bit
                    if isempty(obj.owner) && ~isempty(obj.dev_name)
                        fprintf('Logger constructor v%4.2f | name: %s\n', obj.version, obj.dev_name);
                    elseif ~isempty(obj.owner) && isempty(obj.dev_name)
                        fprintf('Logger constructor v%4.2f | owner: %s\n', obj.version, class(obj.owner));
                    else
                        fprintf('Logger constructor v%4.2f | name: %s | owner: %s\n', obj.version, obj.dev_name, class(obj.owner));
                    end
                end
                
            else
                if obj.debug_bit
                    fprintf('Logger constructor v%4.2f\n', obj.version);
                end
            end
            
        end
        
        function delete(obj) % custom destructor to make sure file is closed
            
            try 
            
                if ~isempty(obj.hndl)
                    fclose(obj.hndl);
                end
            
            catch ME
                warning(ME.getReport);
            end
            
        end
        
    end
    
    methods % reset /clear
        
        function reset(obj) % close all files and reset file handles and time object
            
            obj.time = datetime.empty;
            obj.filename = '';
            
            try 
                
                if ~isempty(obj.hndl)
                    fclose(obj.hndl);
                end
                
                if ~isempty(obj.hndl_err)
                    fclose(obj.hndl_err);
                end
                
            catch ME
                warning(ME.getReport);
            end
            
            obj.hndl = [];
            obj.hndl_err = [];
            
        end
        
    end
    
    methods % getters
        
        function val = get.base_dir(obj) % allow user to override the <base_dir> property
        
            if isempty(obj.base_dir)
                val = fullfile(util.def.data_folder, 'WFAST/logfiles');
            else
                val = obj.base_dir;
            end
            
        end
        
        function val = get.filename(obj) % allow user to override the <filename> property
            
            if isempty(obj.filename)
                val = [util.sys.date_dir(obj.time) '_' obj.dev_name '.txt'];
            else
                val = obj.filename;
            end
            
        end
        
        function val = get.fullname(obj) % combine <basedir>/<filename>
            
            val = fullfile(obj.base_dir, util.sys.date_dir(obj.time), obj.filename);
            
        end
        
        function val = err_filename(obj) % error filename is the same as <filename> with _ERROR appended
            
            [~, name, ext] = fileparts(obj.filename);
            
            val = [name '_ERROR' ext];
            
        end
        
        function val = err_fullname(obj) % combine <basedir>/<filename>
            
            val = fullfile(obj.base_dir, util.sys.date_dir(obj.time), obj.err_filename);
            
        end
        
    end
    
    methods % setters
        
    end
    
    methods % commands
        
        function input(obj, text, errflag) % give bit of text to write to log files. Use errflag=1 to denote errors (default=0) 
            
            if nargin<3 || isempty(errflag)
                errflag = 0;
            end
            
            text = util.text.eraseTags(text);
            
            new_time = datetime('now', 'timezone', 'UTC'); % update to current time
            
            % if we passed noon UTC we should generate new log files
            if ~isempty(obj.time) && new_time.Day>=obj.time.Day && new_time.Hour>=12 && obj.time.Hour<12
                obj.reset;
            end
            
            old_time = datetime(obj.filename(1:10), 'TimeZone', 'UTC');
            
            if hours(new_time-old_time)>24 || (new_time.Day==old_time.Day && new_time.Hour>=12 && old_time.Hour<12)
                obj.reset;
            end
            
            obj.time = new_time;
            
            timestamp = datestr(obj.time, 'hh:MM:ss.FFF');
            
            if errflag==0
                obj.report = sprintf('%s: %s', timestamp, text); % timestamp and input text 
            else
                obj.report = sprintf('************ EXCEPTION *****************\n%s: %s', timestamp, text); % add banner
            end
            
            if isempty(obj.hndl) || obj.hndl<0
                obj.makeFile; % make sure the file exists or create a new one if needed
            end
            
            if obj.use_error_file && (isempty(obj.hndl_err) || obj.hndl_err<0)
                obj.makeErrFile;
            end
            
            
            try 
                
                fprintf(obj.hndl, '%s\n', obj.report); % print line to normal file
                
                if obj.use_error_file && errflag
                    fprintf(obj.hndl_err, '%s\n', obj.report); % print error line to additional error file
                end
                
            catch ME
                warning(ME.getReport);
            end
            
        end
        
        function error(obj, text) % just call input(<text>, errflag=true)
            
            obj.input(text, 1); % use the errflag! 
            
        end
        
        function makeFile(obj) % make the text file, folder (if needed) and keep the filename
            
            dir = obj.base_dir;
            
            if obj.use_date_dir
                dir = [dir '/' util.sys.date_dir(obj.time)];
            end
            
            if ~exist(dir, 'dir')
                mkdir(dir)
            end
            
            try 
                
                obj.hndl = fopen(obj.fullname, 'at');
                
                if obj.hndl<0
                    obj.hndl = [];
                    error('Cannot open the file %s', obj.fullname);
                end
                
            catch ME
                warning(ME.getReport);
            end
            
        end
        
        function makeErrFile(obj) % if writing to extra error file, this makes it
            
            dir = obj.base_dir;
            
            if obj.use_date_dir
                dir = [dir '/' util.sys.date_dir(obj.time)];
            end
            
            if ~exist(dir, 'dir')
                mkdir(dir)
            end
            
            try 

                obj.hndl_err = fopen(obj.err_fullname, 'at');

                if obj.hndl_err<0
                    obj.hndl_err = [];
                    error('Cannot open the file %s', obj.err_fullname);
                end

            catch ME
                warning(ME.getReport);
            end 
            
        end
        
        function val = check_heartbeat(obj) % check if heartbeat timer is running
            
            val = ~isempty(obj.timer) && isa(obj.timer, 'timer') && isvalid(obj.timer) && strcmp(obj.timer.Running, 'on');
            
        end
        
        function heartbeat(obj, time_sec, owner) % if owner exists, update it and check the status. Otherwise just print time: heartbeat
            
            if nargin<2 || isempty(time_sec)
                time_sec = 300; % five minutes default interval
            end
            
            if nargin>2 && ~isempty(owner) && isobject(owner)
                obj.owner = owner;
            end
            
            if obj.check_heartbeat
                stop(obj.timer);
                delete(obj.timer);
                obj.timer = [];
            end
            
            % use time_sec='off' to stop heartbeat timer
            if ischar(time_sec) && util.text.cs(time_sec, 'off')
                return;
            end
            
            % use time_sec<=0 to stop timer
            if isnumeric(time_sec) && time_sec<=0
                return;
            end
            
            obj.timer = timer('BusyMode', 'queue', 'ExecutionMode', 'fixedRate', 'Name', ['timer-' obj.dev_name], ...
                'Period', time_sec, 'StartDelay', 0, 'TimerFcn', @obj.timer_callback, 'ErrorFcn', ''); % maybe add a restart when calling ErrorFcn
            
            start(obj.timer);
            
        end
        
        function timer_callback(obj, ~, ~) % This is called by the heartbeat timer
                
            if ~isempty(obj.owner)
                
                if ismethod(obj.owner, 'update')
                    obj.owner.update;
                elseif ismethod(obj.owner, 'Update')
                    obj.owner.Update;
                end
            
                str = '';
                
                if isprop(obj.owner, 'printout') || ismethod(obj.owner, 'printout')
                    str = obj.owner.printout;
                elseif isprop(obj.owner, 'Printout') || ismethod(obj.owner, 'Printout')
                    str = obj.owner.Printout;
                elseif isprop(obj.owner, 'status')  
                    str = obj.owner.status;
                elseif isprop(obj.owner, 'Status')
                    str = obj.owner.Status;
                end
                
                if isnumeric(str)
                    str = num2str(str);
                end
                
                obj.input(['Heartbeat: ' str]);
            
            else
                obj.input('Heartbeat...');
            end
            
        end
            
    end
    
end

