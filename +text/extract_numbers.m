function numbers = extract_numbers(str)
% Usage: numbers = extract_numbers(str)
% Extracts all numeric values from a string into a cell array. 
% Example: extract_numbers('RA: 12.3 | Dec: -03.4') returns 12.3 and -3.4. 
% 
% Output is always a cell array, with one cell for each string. 
% In each cell there will be a vector of numbers extracted. 
% If there are no numbers the cell contains an empty vector. 

    if nargin==0
        help('util.text.extract_numbers');
        return;
    end

    if isnumeric(str)
        numbers = str;
        return;
    end

    if ischar(str)
        str = {str};
    end

    numbers{length(str)} = [];
    
    for ii = 1:length(str) % go over all strings
        
        string = str{ii};
        temp_numbers = [];
        temp_extraction = '';
             
        for jj = 1:length(str{ii}) % go over the letters in one string
                       
            if (string(jj)>='0' && string(jj)<='9') || string(jj)=='.' || string(jj)=='-' || string(jj)=='+' ||...
                    (~any(temp_extraction=='e') && ~any(temp_extraction=='E') && jj~=1 && jj~=length(string) && string(jj)=='e') ||...
                    (~any(temp_extraction=='e') && ~any(temp_extraction=='E') && jj~=1 && jj~=length(string) &&string(jj)=='E')
            
                temp_extraction(end+1) = string(jj);
                
            elseif length(string)>=jj+2 && string(jj)=='N' && string(jj+1)=='a' && string(jj+2)=='N'
                temp_numbers(end+1) = NaN;
                jj = jj+2;
            else
                
                if ~isempty(temp_extraction)
                    
                    a = sscanf(temp_extraction, '%f');
                    if ~isempty(a), temp_numbers(end+1) = a; end
                    
                end
                
                temp_extraction = '';
                
            end
            
        end %% end jj
        
        if ~isempty(temp_extraction)
            
            a = sscanf(temp_extraction, '%f');
            if ~isempty(a), temp_numbers(end+1) = a; end
            
        end
        
        numbers{ii} = temp_numbers;
            
    end % end ii

end