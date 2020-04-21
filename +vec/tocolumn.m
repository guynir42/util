function v_col = tocolumn(vector)
% Usage: v_col = tocolumn(vector)
% If input is not a column, tocolumn turns it to a column vector. 
% if input vector is a matrix, tocolumn does nothing but displays a warning

    if nargin==0
        help('util.vec.tovector');
        return;
    end
    
    if isempty(vector)
        v_col = vector;
        return;
    end
    
    vector = squeeze(vector);

    if ~isvector(vector)
        disp(['warning: input to "tocolumn" is a matrix of size ' num2str(size(vector))]);
        v_col = vector;
        return;
    end
    
    if isrow(vector)
        vector = vector';
    end
    
    v_col = vector;

end