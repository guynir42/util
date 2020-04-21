function values_conv = convolution(kernels, values, varargin)
% Usage: values_conv = convolution(kernels, values, varargin)
% Run convolution or cross-correlation of "kernels" with "values". 
% Both inputs can be any size vector or matrix, but any non-singleton dimensions
% beyond dim1 must match (i.e., they are both padded to the same length in 
% dimension 1 and then multiplied. This also gives the dimensions of the output).
%
% This function runs in Fourier space and requires a lot of memory if these 
% are big matrices, especially if one has large dim2 and the other dim3 
% (the output and intermediate matrices will have dim1*dim2*dim3 size). 
%
% OPTIONAL ARGUMENTS:
%  *cross: cross-correlation instead of convolution (i.e., use complex 
%          conjugate in Fourier space). Default is false. 
%  *crop: what is the final region of the result. "same" (default) outputs 
%         the same size, "valid" gives only the region the has full overlap, 
%         "full" gives the joint size with mutual padding.
%  *normalize: Use this option to subtract the mean and divide by the std, 
%              for "values", "kernels", or "both". 
%  *debug_bit: Level of verbosity (default 0). 
%  *mem_max: Maximum available memory (in GBs) for multiplying big matrices. 
%            If the calculation requires more than this, it is done in a 
%            very slow loop... 

    import util.text.cs;

    if nargin==0, help('util.vec.convolution'); return; end

    input = util.text.InputVars;
    input.input_var('cross', 0, 'conj'); 
    input.input_var('crop', 'same'); 
    input.input_var('normalize', '');
    input.input_var('debug_bit', 0); 
    input.input_var('mem_max', 10, 'memory max', 'memory limit'); 
    input.scan_vars(varargin{:});
    
    Sv = size(values);
    Sk = size(kernels);
    
    D = max(length(Sv), length(Sk)); % largest dimension of both inputs
    Sk = [Sk, ones(1,D-length(Sk))];
    Sv = [Sv, ones(1,D-length(Sv))];
    
    L = Sk(1) + Sv(1) - 1; % adjusted length of dim1 for both kernels and values
    
    Sk_adj = Sk;
    Sk_adj(1) = L;
    Sv_adj = Sv;
    Sv_adj(1) = L;
    
    matched_dims = Sk_adj==1 | Sv_adj==1 | Sk_adj==Sv_adj; % each dimension must be either scalar, or the same size
    
    if ~all(matched_dims)
        error('Size mismatch between "kernels" (%s) and "values" (%s)', util.text.print_vec(Sk, 'x'), util.text.print_vec(Sv, 'x'));
    end

    S_out = max(Sv,Sk); % the size of the output (dim1 of this may change in the end when we crop it)
    S_out(1) = L;
    
    if nnz(isnan(kernels)), warning('Input "kernels" has NaN values!'); end
    if nnz(isnan(values)), warning('Input "values" has NaN values!'); end
    
    %%%%%%%%%%%%% finsihed verifying sizes, can start calculations %%%%%%%%%%%%%%%
    
    k = kernels;
    
    if cs(input.normalize, 'kernels', 'both')
        k = (k-nanmean(k))./nanstd(k);
    end
        
    k = util.img.pad2size(k, Sk_adj);
    kernels_fft = fft(k);
    
    if input.cross
        kernels_fft = conj(kernels_fft);
    end

    % if values ends up having many dimensions (above 4) we will need to patch the pad2size function 
    
    v = values;
    
    if cs(input.normalize, 'values', 'both')
        v = (v-nanmean(v))./nanstd(v);
    end
    
    v = util.img.pad2size(v, Sv_adj); % keep all dimensions of values except the first, which is padded
    
    values_fft = fft(v);

    if isa(values, 'single') && isa(kernels, 'single')
        bytes = 4;
    else
        bytes = 8;
    end
    
    memory_needed = prod(S_out)*bytes*2/1024^3; % factor of 2 is for complex numbers in the FFT
    
    if input.debug_bit
        fprintf('Memory requirements for output array size [%s] is %4.1fGb\n', util.text.print_vec(S_out, 'x'), memory_needed);
    end 
    
    try
        if memory_needed>input.mem_max
            if input.debug_bit, disp('Memory required is too large. Using a loop instead!'); end
            values_conv = fft_in_a_loop(kernels_fft, values_fft, S_out, Sk, Sv);
        else
            values_conv = real(fftshift(ifft(kernels_fft.*values_fft),1)); % just do the whole thing at once
        end
    catch ME
        if strcmp(ME.identifier, 'MATLAB:nomem')
            disp('Out of memory error... Using a loop instead!');
            values_conv = fft_in_a_loop(kernels_fft, values_fft, S_out, Sk, Sv);
        else
            rethrow(ME);
        end
        
    end

    %%%%%%%%%%%%%% Just crop it to the correct output size %%%%%%%%%%%%%%%%
    
    if util.text.cs(input.crop, 'same')
        S_out(1) = Sv(1);
        values_conv = util.img.crop2size(values_conv, S_out); % crop back to original dimensions...
    elseif util.text.cs(input.crop, 'valid')
        S_out(1) = Sv(1) - Sk + 1;
        values_conv = util.img.crop2size(values_conv, S_out);
    elseif util.text.cs(input.crop, 'full')
        % pass
    else
        error('Unknown "crop" value "%s". Try "same" or "valid" or "full".', input.crop);
    end
    
end

function M = fft_in_a_loop(kernels_fft, values_fft, S_out, Sk, Sv)

    accessor = repmat({':'}, [1,length(S_out)]); % a cell array that looks like {':',':',':'}
    accessor_v = accessor;
    accessor_k = accessor;
    accessor_out = accessor;

    loop_idx = find(S_out(2:end)>1, 1, 'last')+1; % the last non-singleton dimension is split up into a loop

    if isa(kernels_fft, 'single') && isa(values_fft, 'single')
        M = zeros(S_out, 'single');
    else
        M = zeros(S_out);
    end

    for ii = 1:S_out(loop_idx)

%         fprintf('ii= %d\n', ii);
        
        if Sk(loop_idx)>1 % kernels are non-singleton in this dimension
            accessor_k{loop_idx} = ii; % now it looks like {':',ii,':',':'}
        end

        if Sv(loop_idx)>1 % values are non-singleton in this dimension
            accessor_v{loop_idx} = ii; % now it looks like {':',ii,':',':'}
        end

        accessor_out{loop_idx} = ii; 

        M(accessor_out{:}) = real(fftshift(ifft(kernels_fft(accessor_k{:}).*values_fft(accessor_v{:})),1));

    end

end




