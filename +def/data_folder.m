function val = data_folder
% usage: val = data_folder
% Non-input function just gives the directory for data. 
% Calls getenv('DATA') and gives an error if it is empty/undefined/doesn't exist. 

    val = getenv('DATA');
    
    if isempty(val)
        error('Must define an environmental variable for "DATA"'); 
    end
    
    if ~exist(val, 'dir')
        error('Environmental variable for "DATA"=%s does not exist on this system!', val);
    end

end