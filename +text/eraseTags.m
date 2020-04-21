function str_out = eraseTags(str)
% usage: str_out = eraseTags(str)
% Removes html like hyperlinks. 
% Can be replaced with matlab's built-in eraseTags after 2017b

    str_out = regexprep(str, '<a\s.*?>[^@]|</a>', '');

end