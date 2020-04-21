function v_page = topages(vector)
% Usage: v_page = topages(vector)
% If input is not a 3D vector (i.e., dim 1 & 2 singletons), 
% topages() turns it into a 3D vector. 
% If input vector is a matrix, topages does nothing but displays a warning. 

    if nargin==0
        help('util.vec.topages');
        return;
    end
    
    if isempty(vector)
        v_page = vector;
        return;
    end
    
    vector = squeeze(vector);

    if ~isvector(vector)
        disp(['warning: input to "topages" is a matrix of size ' num2str(size(vector))]);
        v_page = vector;
        return;
    end
    
    if isrow(vector)
        vector = vector';
    end
    
    v_page = permute(vector, [3,2,1]);

end