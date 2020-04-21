function v_row = torow(vector)
% Usage: v_row = torow(vector)
% If input is not a row, torow turns it to a row vector. 
% If input vector is a matrix, torow does nothing but displays a warning

    if nargin==0
        help('util.vec.torow');
        return;
    end
    
    if isempty(vector)
        v_row = vector;
        return;
    end

    vector = squeeze(vector);
    
    if ~isvector(vector)
        disp(['warning: input to "torow" is a matrix of size ' num2str(size(vector))]);
        v_row = vector;
        return;
    end
    
    if iscolumn(vector)
        vector = vector';
    end
    
    v_row = vector;

end