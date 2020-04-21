function time = str2time(str, anchor_timestamp, additional_timestamps)
% Usage: time = str2time(str, [anchor_timestamp, additional_timestamps])
% Parses a time string (FITS format compliant) into a datetime object.
% Will always define the datetime object in UTC (there are no other times!)
%
% If given 3 arguments, will translate the 3rd ("additional_timestamps")
% into datetime objects, based on the 1st and second arguments, which have
% to be a string (absolute time) and a timestamp (relative time). 

    if nargin==0, help('util.text.str2time'); return; end

    if isempty(str) || all(strcmp(str, '[]'))
        time = datetime.empty;
        return;
    end
    
    timezone = 'UTC';
    
    if ischar(str)
        vec = sscanf(str, '%4d-%2d-%2dT%2d:%2d:%f')';
    elseif iscell(str)
        for ii = 1:length(str)
            vec(ii,:) = sscanf(str{ii}, '%4d-%2d-%2dT%2d:%2d:%f')';
        end
    else
        error('Must supply a string or cell of strings to "str2time"! Instead got %s.', class(str));
    end
    
    time = datetime(vec, 'TimeZone', timezone);
    
    if nargin==3 
    
        if isempty(anchor_timestamp) || ~isnumeric(anchor_timestamp)
            error('Must supply a non-empty, numeric timestamp as 2nd argument!');
        end
    
        time = time + seconds(additional_timestamps-anchor_timestamp);
        
    end
    
    
end