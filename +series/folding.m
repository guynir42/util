function [f_folded, std_folded] = folding(f, num_samples, varargin)
% Usage: [f_folded, std_folded] = folding(f, num_samples, varargin)
% Fold the flux data f along a period with "num_samples" bins. 
% The data must be aligned with time on the first dimension, other dimensions
% can be anything else. 
% The flux should be evenly sampled, with any gaps replaced by NaNs. 
% It is usually also a good idea to remove slow trends and to subtract the 
% average of each flux before folding. 
%
% Optional arguments:
%   -median: use median instead of mean of each phase bin.
%   
%
%
% Output: The folded flux, the mean (or median) in each phase bin.  
%         If an additional output argument is given, will output the std in 
%         each phase bin as well. 


    if nargin==0, help('util.series.folding'); return; end
    
    if num_samples==1 || num_samples>size(f,1)
        error('Must give "num_samples" to be larger than 1 and smaller than the length of f');
    end
    
    num_samples = round(num_samples);
    
    input = util.text.InputVars;
    input.input_var('median', false, 'use_median');
    input.scan_vars(varargin{:});
    
    S = size(f); % keep track of the original size of the input
    N = floor(size(f,1)./num_samples).*num_samples; % the number of samples that divide cleanly by num_samples
    
    f = f(:,:); % linearize all higher dimensions... 
    
    if N~=size(f,1)
        f = vertcat(f,NaN(N+num_samples - size(f,1), size(f,2))); % add NaNs to the end of the lightcurve to make it divisible by num_samples
    end
    
    f = reshape(f, [num_samples size(f,1)./num_samples size(f,2)]); % now the 1st dimension has the length num_samples, the 2nd has different periods and 3rd all the original other dims. 
    
    if input.median
        f_folded = nanmedian(f,2);
    else
        f_folded = nanmean(f,2);
    end
    
%     f_folded = permute(f_folded, [1,3,2]); % get rid of dim 2 which we just integrated over
    f_folded = reshape(f_folded, [size(f_folded,1), S(2:end)]);
    
    if nargout>1
        
    end

