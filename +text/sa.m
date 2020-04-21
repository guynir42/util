function str_out = sa(str1, str2, ext)
% Usage: sa(str1, str2, [ext])
% Concatenates two strings, maiking sure they have a '/' between them. 
%
% Optional argument "ext" adds an extension (as in, ".ext" to the string). 
%
% This function is slowly being removed from my code in favour of the built
% in function fullfile(). 

    if nargin==0
        help('util.text.sa');
        return;
    end

    if isempty(str1)
        str_out = str2;
        return;
    end
    
    if nargin<3 || isempty(ext)
        ext = [];
    end
    
    if isa(str1, 'util.WorkingDirectory')
        str1 = str1.pwd;
    end
    
    if nargin<2 || isempty(str2)
        str_out = str1;
        return;
    end

    slash = '/';
   
    if str2(1)=='/' || str2(1)=='\'
        str2 = str2(2:end);
    end
    
    if str1(end)=='/' || str1(end)=='\'
        str_out = [str1 str2];
    else
        str_out = [str1 slash str2];
    end
    
    if ~isempty(ext)
        if ext(1)~='.'
            ext = ['.' ext];
        end
        str_out = [str_out ext];
    end
    
end