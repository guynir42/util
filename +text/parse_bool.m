function val = parse_bool(input)
% Usage: val = parse_bool(input)
% Converts logicals, numbers or text to logical zero or non-zero.
% If given a string, the values 'yes', 'on', 'true' will output true (case-
% insensitive). All other strings output false.
% Numerical inputs are returned as logicals. 
% Strings containing numerals are turned to numbers and then to logical. 
% e.g. the input '1' is true. 

    if nargin==0, help('util.text.parse_bool'); return; end

    if isnumeric(input) || islogical(input)
        val = input;
    elseif ischar(input)
        
        val = str2num(input);
        
        if isempty(val) % if we cannot parse the string as a number, it may be yes/no or something like that

            if any(strcmpi(input, {'yes', 'on', 'true'}))
                val = 1;
            else % any other word is translated to false
                val = 0;
            end

        end
        
    else
        error('Unknown data type "%s" for input. Try using logical, numeric, or string inputs.', class(input)); 
    end
    
    val = logical(val); 

end