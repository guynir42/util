function M_out = mad2(M,varargin)
% Finds the Median Absolute Deviation of an image (MAD). 
% Usage: mad2(M, varargin)
% More robust than variance/standard deviation. 
%
% Input: A matrix (can be 3D or 4D, using loops...). 
% Output: The median (or mean) absolute deviation (can be 3D or 4D vector).
% OPTIONAL ARGUMENTS:
%   -type: choose 'median' (default) or 'mean'
%   -multiply or sigma: use this flag to multiply the return values to
%    match the normal distribution sigma parameter (default is "off").
%

    import util.text.cs;
    import util.text.parse_bool;

    if nargin==0
        help('util.stat.mad2');
        return;
    end

    type = 1; % this is for 'median', 0 is for 'mean'
    sigma = 0;
    
    for ii = 1:2:length(varargin)
        key = varargin{ii};
        val = varargin{ii+1};
        
        if cs(key, 'type')
            if cs(val, 'median')
                type = 1;
            elseif cs(val, 'mean')
                type = 0;
            else
                error(['Unknown type option "' val '". Use median or mean...']);
            end
        elseif cs(key, 'sigma', 'multiply')
            sigma = parse_bool(val);
        end            
        
    end
    
    M_out = zeros(1,1,size(M,3), size(M,4));

    for ii = 1:size(M,3)
        for jj = 1:size(M,4)
            single_image = M(:,:,ii,jj);
            M_out(1,1,ii,jj) = mad(single_image(:), type);
        end
    end
    
    if sigma % match to standard deviation (for normal dist. only!)
        if type
            M_out = M_out*1.4826;
        else
            M_out = M_out*1.253;
        end
    end
    
end