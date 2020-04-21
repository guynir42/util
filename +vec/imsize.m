function S = imsize(input, treat_as)
% Usage: S = imsize(input, treat_as=[])    
% Takes a scalar, vector or matrix and returns the 2 element image size 
% If input is scalar, returns [1,1]*input
% If input is a 2 element vector, or empty, returns input. 
% If input is a row vector, returns first two elements. 
% If input is column or a matrix, return the size of first 2 dimensions. 
% Use "treat_as" secondary input to avoid confusion (e.g. if input image 
% somehow has a vector/scalar size). Use "size" or "matrix". 

    if nargin==0, help('util.vec.imsize'); return; end

    if nargin<2
        treat_as = [];
    end
    
    if isempty(treat_as)
        if isempty(input)
            S = [];
        elseif isscalar(input)
            S = [1,1]*input;
        elseif length(input)==2
            if isrow(input)
                S = input;
            else 
                S = input';
            end
        elseif isrow(input)
            S = input(1:2);
        else
            S = size(input);
            S = S(1:2);
        end
    elseif util.text.cs(treat_as, 'size')
        if isempty(input)
            S = [];
        elseif isscalar(input)
            S = [1,1]*input;
        else
            if iscolumn(input)
                S = input(1:2)';
            else 
                S = input(1:2);
            end
        end
    elseif util.text.cs(treat_as, 'matrix')
        S = size(input);
        S = S(1:2);        
    else
        error('Unknown option %s for "treat_as". Try "size" or "matrix"...', treat_as);
    end
    
end