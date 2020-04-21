function M_out = conv_f(kernel, image, varargin)
% usage: conv_f(kernel, image, varargin). 
% performs convolution/filter of image with kernel. 
% will use FFT instead of brute force if it estimates it is faster. 
% OPTIONAL ARGUMENTS:
% -conjugate: do cross correlation instead of convolution. 
% -crop: which output size to use: same (default), full.
% -fft: turn FFT on or off or set to auto (default). 
% -mem_limit: if limit is exceeded, use loop instead of 3D matrices. 
%             given in GB, default is 30. 
% 
    
    import util.img.pad2size;
    import util.img.crop2size;
    import util.text.cs;
    import util.text.parse_bool;
    import util.img.conv_f;
    
    % parse varargin
    
    conjugate = 0;
    crop = 'full';
    mem_limit_gb = util.sys.free_ram('GBs');
    use_fft = [];
    
    if ~isempty(varargin) && mod(length(varargin),2)==1
        varargin{end+1} = 1; % positive approach
    end
    
    for ii = 1:2:length(varargin)
        if cs(varargin{ii}, 'conjugate')
            conjugate = parse_bool(varargin{ii+1});
        elseif cs(varargin{ii}, 'crop')
            crop = varargin{ii+1};
        elseif cs(varargin{ii}, {'memory_limit', 'mem_limit'})
            mem_limit_gb = varargin{ii+1};
        elseif cs(varargin{ii}, {'use_fft', 'fft'})
            use_fft = parse_bool(varargin{ii+1});
        end
    end
        
    if isempty(use_fft)
        
        N = (size(kernel,1)+size(image,1)-1)*(size(kernel,2)+size(image,2)-1);
        calc_time_fft = 50*N*log2(N)*size(image,3); % there's a fudge factor of about 50 for the FFT convolution deal
        
        calc_time_conv = numel(image)*numel(kernel);
        
%         fprintf('calc_time_fft= %e | calc_time_conv= %e\n', calc_time_fft, calc_time_conv);

        if calc_time_conv>calc_time_fft
            use_fft = 1;
        else
            use_fft = 0;
        end
        
    end
        
    SK = size(kernel);
    SK = SK(1:2);
    SI = size(image);
    SI = SI(1:2);
    
    S = SK + SI - 1;
    
    bytes = max(util.sys.getElementSize(image), util.sys.getElementSize(kernel)); % number of bytes per pixel
    
    if ~use_fft % just skip using fft
        if cs(crop, 'full')
            M_out = zeros([S size(image,3)], 'like', image);
        elseif cs(crop, 'same')
            M_out = zeros([SI size(image,3)], 'like', image);
        end
        
        for jj = 1:size(image,4)
            for ii = 1:size(image,3)
                
                k = kernel;
                if size(kernel,4)>1
                    k = k(:,:,:,jj);
                end
                
                if size(kernel,3)>1
                    k = k(:,:,ii);
                end
                
                if conjugate
                    M_out(:,:,ii,jj) = filter2(k, image(:,:,ii,jj), crop);
                else
                    M_out(:,:,ii,jj) = conv2(image(:,:,ii,jj), k, crop);
                end
                
            end
        end
        
    elseif S(1)*S(2)*size(image,3)*bytes*4>1024^3*mem_limit_gb % out of memory, use conv_f on slices 
        
        if size(image,3)>1 || size(image,4)>1

            disp(['memory exceeded: ' num2str(S(1)*S(2)*size(image,3)*16*4/1024^3) 'Gb... using slices of matrices instead']);
            
            if cs(crop, 'full')
                M_out = zeros([S size(image,3) size(image,4)]);
            elseif cs(crop, 'same')
                M_out = zeros([SI size(image,3) size(image,4)]);
            end

            for jj = 1:size(image,4)
                for ii = 1:size(image,3)
                    
                    k = kernel;
                    
                    if size(kernel,4)>1
                        k = k(:,:,:,jj);
                    end
                    
                    if size(kernel,3)>1
                        k = k(:,:,ii);
                    end
                    
                    M_out(:,:,ii,jj) = conv_f(k, image(:,:,ii,jj), varargin{:});
                    
                end
            end
            
        else % for single images, we can't recursively call conv_f to save memory. instead use conv2/filter2
            
            disp(['memory exceeded: ' num2str(S(1)*S(2)*size(image,3)*16*4/1024^3) 'Gb... in single slice... using conv2/filter2 instead...']);
            if conjugate
                M_out = filter2(kernel, image, crop);
            else
                M_out = conv2(kernel, image, crop);
            end
        end
                    
    else % use the full power of fft2 to do the convolution!
        
        kernel_f = fft2(pad2size(kernel, S));
        image_f = fft2(pad2size(image, S));

        if conjugate
            kernel_f = conj(kernel_f);
        end
        
        M_out = real(fftshift(fftshift(ifft2(kernel_f.*image_f),1),2));

        if cs(crop, 'full')
            % do nothing
        elseif cs(crop, 'same')
            M_out = crop2size(M_out, SI);
        elseif cs(crop, 'valid')
            M_out = crop2size(M_out, SI-SK+1);
        else
            error('Unkown crop option "%s". Use "full", "same" or "valid"...', crop);
        end
    
    end
    
end