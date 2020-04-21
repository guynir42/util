function I_out = downsample(I, binning, normalization, memory_limit)
% usage: downsample(I, binning=2, normalization='sum', memory_limit=10GBs)
% Bins an image (downsample) by convolving with a square kernel and then
% jumping in index sampling.
% OPTIONAL PARAMETERS
%   -binning: by how much to down sample. Must be an integer. Default is 2
%   -normalization: sum (default) or mean of all pixels that turn into one. 
%   -memory limit: maximum amount of memory (in GBs) to use for FFT. If the
%    size of array exceeds it, conv_f will loop on the pages of I. 

    if nargin==0, help('util.img.downsample'); return; end
    
    if isempty(I)
        I_out = [];
        return;
    end
    
    if nargin<2 || isempty(binning)
        binning = 2;
    end
    
    if nargin<3 || isempty(normalization)
        normalization = 'sum';
    end
    
    if nargin<4 || isempty(memory_limit)
        memory_limit = 10; % GBs
    end
    
    if binning==1 % if no binning is needed just get out...
        I_out = I;
        return;
    end
    
    binning = round(binning);
    k = ones(binning, 'like', I);
    
    if util.text.cs(normalization, 'mean')    
        k = k./sum(k(:));
    end
    
    % conv_f will choose if to use FFT convolution, also might loop through 3D matrix 
    I_conv = util.img.conv_f(k, I, 'mem_limit', memory_limit); 
    
%     index = mod(size(I),binning)+ 1; % starting index for sampling...
%       I_out = I_conv(index(1):binning:end-binning, index(2):binning:end-binning, :);

    I_out = I_conv(binning:binning:end, binning:binning:end);

end