function [rms, freq] = noise_spec(f, num_samples, varargin)
% Usage: [rms, freq] = noise_spec(f, num_samples, varargin)
% Calculate the average noise in each frequency by breaking the lightcurve
% into segments and calculating the power spectrum for each one. 
% 
% Optional arguments:
%
% Outputs: The noise rms in each frequency, up to the nyquist sampling. 
%          The frequency axis is also returned, using the optional
%          "sampling" parameter (default is 1 Hz). 
% 
% 

    if nargin==0, help('util.series.noise_spec'); return; end
    
    if num_samples==1 || num_samples>size(f,1)
        error('Must give "num_samples" to be larger than 1 and smaller than the length of f');
    end
    
    num_samples = round(num_samples);
    
    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('sampling', 1); 
    input.scan_vars(varargin{:});
    
    S = size(f); % keep track of the original size of the input
    N = floor(size(f,1)./num_samples).*num_samples; % the number of samples that divide cleanly by num_samples
    
    f = f(:,:); % linearize all higher dimensions... 
    
    if N~=size(f,1)
        f = vertcat(f,zeros(N+num_samples - size(f,1), size(f,2))); % add NaNs to the end of the lightcurve to make it divisible by num_samples
    end
    
    f = reshape(f, [num_samples size(f,1)./num_samples size(f,2)]); % now the 1st dimension has the length num_samples, the 2nd has different periods and 3rd all the original other dims.
    
    f = fillmissing(f, 'linear');
    ff = fft(f); % calculate the FFT along the 1 dimension (for different segments separately)
    
    rms = abs(std(ff,[],2)); 
    rms = rms(1:floor(size(rms,1)/2),:);
%     rms = rms(1:floor(size(rms,1)/2),:,:) + flipud(rms(floor(size(rms,1)/2)+1:end,:,:)); 
    
    rms = reshape(rms, [size(rms,1), S(2:end)]);
    
    freq = (0:floor(num_samples/2)-1)'./num_samples.*input.sampling; 
    
    
    
    
    
    
    
    
    
    