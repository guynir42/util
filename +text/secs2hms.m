function time_string_out = secs2hms(time_in_secs)
% Usage: time_string_out = secs2hms(time_in_secs);
% Converts a time in seconds to a string giving the time in hours, minutes and seconds
% Example 1: 
% >> secs2hms(7261)
%       2 hours, 1 min, 1.0 sec
% Example 2: 
% >> tic; pause(61); disp(['program took ' secs2hms(toc)]);
%       program took 1 min, 1.0 secs
%
% If no output argument is given, it just prints the information. 
    
    if nargin==0, help('util.text.secs2hms'); return; end
    
    time_string='';
    nhours = 0;
    nmins = 0;
    if time_in_secs >= 3600
        nhours = floor(time_in_secs/3600);
        if nhours > 1
            hour_string = ' hours, ';
        else
            hour_string = ' hour, ';
        end
        time_string = [num2str(nhours) hour_string];
    end
    if time_in_secs >= 60
        nmins = floor((time_in_secs - 3600*nhours)/60);
        if nmins > 1
            minute_string = ' mins, ';
        else
            minute_string = ' min, ';
        end
        time_string = [time_string num2str(nmins) minute_string];
    end
    nsecs = time_in_secs - 3600*nhours - 60*nmins;
    time_string = [time_string sprintf('%2.1f', nsecs) ' secs'];
    
    if nargout==0
        disp(time_string)
    else
        time_string_out = time_string;
    end
    
end