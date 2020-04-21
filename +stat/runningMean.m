function [M_out, N_out] = runningMean(M_old, N_old, S_new, N_new)
% adds together matrices and get their mean
% input: M_old and N_old is the old mean matrix and the number of images already
% added to it. M_new and N_new is the input sum matrix and its number of images. 
% output is the resulting, updated mean matrix, and the new number of images

    if nargin<4 || isempty(N_new)
        N_new = 1;
    end

    if isempty(M_old)
        M_out = S_new/N_new;
        N_out = N_new;
    else
        N_out = N_old+N_new;
        M_out = (M_old.*N_old + S_new)./(N_out);
    end
    
end