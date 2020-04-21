function val = date_dir(varargin)
% Usage: val = date_dir(date)
% Print the date given in YYYY-MM-DD format. If the date given is in the 
% first 12 hours of the day (in UTC!) then give last night's date. 
% This makes sure observations started on a specific date, have the same 
% date and same folder even after midnight. 
% 
% Input: can be a datetime object or the inputs given to a datetime constructor. 
%
% Examples:
%   >> util.sys.date_dir('2020-02-09')
%   >> util.sts.date_dir(datetime('now', 'TimeZone', 'UTC'); 
%   >> util.sys.date_dir('now', 'TimeZone', 'UTC')
%

    if nargin==0, help('util.sys.date_dir'); return; end
    
    if length(varargin)==1 && isa(varargin{1}, 'datetime') && ~isempty(varargin{1})
        date = varargin{1}; 
    elseif isempty(varargin{1})
        date = datetime('now', 'TimeZone', 'UTC'); 
    else
        date = datetime(varargin{:});
    end
    
    % make sure each night is in the same folder, even after midnight.
    if date.Hour<12 % this is 14:00 local time, pretty safe to say it is after midnight of the previous night but observations still haven't started on the new night
        date.Day = date.Day - 1;
    end

    val = datestr(date, 'yyyy-mm-dd');
    
end