function [M_out, idx_end] = insert_matrix(M_old, M_new, idx, fill_value, double_up, make_copy)
% Usage: [M_out, idx_end] = insert_matrix(M_old, M_new, idx, fill_value=0, double_up=0, make_copy=1)
%
% Insert matrix "M_new" into matrix "M_old" at position "idx" (upper left corner). 
% If "M_old" is too small it will expand based on the following rules:
% 1) The empty elements will be filled by "fill_value" (default 0). 
% 2) For each dimension, if the new matrix is bigger than the old, the old 
%    just expands to contain it. If the new matrix is smaller, then the old 
%    matrix can expand either to fit the new data or to double its size, if
%    doubling in size includes enough room for the new data. 
% 3) Turning off "double_up" (default 1) will cause the old matrix to expand
%    only enough to contain the new data in all cases. 
%
% The idea is to reduce the number of re-allocations (like in C++ vectors). 
% The user can use output "idx_end" to know what part of M_out contains data
% and what part is just preallocated space. 
%
% If the matrix needs to be expanded, it must make a new copy. 
% However, if the matrix is not expanded, we can use the mex-function 
% injectMatrix() to put the new data into the old, and return the modified
% matrix without making a copy. 
% If "make_copy" is set to true, the output matrix is deliberately separated
% from the input matrix (this is the default, because it is safer, for example
% if the input matrix is shared by other variables, changing it will not trigger
% the copy-on-edit and the changes may appear unexpectedly elsewhere). 
% If "make_copy" is set to false, then the input matrix and the output are 
% both modified. It is very important to use this carefully and only when 
% there are no other copies of that array. 

    if nargin==0, help('util.vec.insert_matrix'); return; end

    if nargin<4 || isempty(fill_value)
        fill_value = 0;
    end
    
    if nargin<5 || isempty(double_up)
        double_up = 0;
    end
    
    if nargin<6 || isempty(make_copy)
        make_copy = 1;
    end
    
    if isempty(M_new) % new matrix is empty, just return the old matrix and the corner idx as given
        M_out = M_old;
        idx_end = idx;
        return;
    end
    
    if isempty(M_old) % the current matrix is empty, we can just place the new to replace it
        M_out = M_new;
        idx_end = size(M_out);
        return;
    end
    
    if ~isscalar(fill_value)
        error('fill_value must be scalar! size(fill_value)= %s', util.text.print_vec(size(fill_value)));
    end
        
    if ~isscalar(double_up)
        error('double_up must be scalar! size(double_up)= %s', util.text.print_vec(size(double_up)));
    end
    
    if length(idx)<ndims(M_new)
        error('length(idx)= %d is smaller than ndims(M_new)= %d', length(idx), ndims(M_new));
    end
    
    if length(idx)<ndims(M_new)
        error('length(idx)= %d is smaller than ndims(M_new)= %d', length(idx), ndims(M_new));
    end
    
    dims = max([ndims(M_old), ndims(M_new), length(idx)]); % maximum number of dimensions of all the inputs given (including idx)
    
    S_old = size(M_old); % size of old matrix
    if length(S_old)<dims
        S_old = [S_old ones(1, dims-length(S_old))]; % make sure the size vector is as long as the index
    end
    
    S_new = size(M_new); % size of new matrix
    if length(S_new)<dims
        S_new = [S_new ones(1, dims-length(S_new))]; % make sure the size vector is as long as the index
    end
    
    S_expand = S_old; % the size we need to get to in order to add the new matrix
    
    idx_end = idx + S_new - 1; % the index of the last positions of the new matrix inside the old. 
    
    % now idx and idx_end are the same length as S_old and S_new (all equal to dims)
    
    for ii = 1:dims
        
        if idx_end(ii)>S_old(ii) % need to expand on this dimension
            
            % only double up the doubled up matrix can contain the new data 
            % (otherwise expand just enough to contain the new data)
            if double_up && S_new(ii)<S_old(ii) && S_old(ii)*2>idx_end(ii) 
                S_expand(ii) = S_old(ii).*2; % double up
            else
                S_expand(ii) = idx_end(ii); % just expand to fit the new data
            end
            
        end
        
    end
    
    
    if any(S_expand>S_old) % now make a new matrix if needed
        if fill_value==0
            M_out = zeros(S_expand, 'like', M_old);
        elseif isnan(fill_value)
            M_out = NaN(S_expand, 'like', M_old);
        elseif isinf(fill_value)
            M_out = Inf(S_expand, 'like', M_old);
        elseif isnumeric(fill_value)
            M_out = fill_value.*ones(S_expand, 'like', M_old);
        else
            error('Must input "fill_value" as a scalar numerical value (or NaN/Inf). class(fill_value)= %s', class(fill_value));
        end
        
        % copy the old data into new matrix
        util.vec.injectMatrix(M_out, M_old); % use mex function to copy the data in-place
        
    else
        M_out = M_old;
        if make_copy && ~isempty(M_out)
            M_out(1) = M_out(1); 
        end
    end
    
    util.vec.injectMatrix(M_out, M_new, idx); % use mex function to copy the data in-place (if we don't re-allocate this saves a ton of time)
    
end






