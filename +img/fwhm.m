function val = fwhm(I, varargin)
% Usage: val = fwhm(I, varargin)
% Calculate the Full Width at Half-Maximum (FWHM) for an image.
% Uses the radialStats function to calculate the mean of each annulus, 
% then finds the point where the value reaches half. 
% Assumes image is a centered, radial distribution!
% 
% OPTIONAL ARGUMENTS:
%   -number_interp: minimal number of points along slope. If the number of
%                   pixels in the image is larger than this, we don't need
%                   to interpolate. Otherwise it will interpolate to this 
%                   number of points. Default is 100. 
%

    if nargin==0, help('util.img.fwhm'); return; end
    
    input = util.text.InputVars;
    input.input_var('number_interp', 100);
    input.scan_vars(varargin{:});
    
    % assume image is centered and padded to odd number of pixels
    
    S = size(I);
    S = S(1:2);
    
    r_max = max(S);
    
    for ii = 1:size(I,3)
        for jj = 1:size(I,4)
            
            [values, radii] = util.img.radialStats(I, 'mean', 'r_min', 0, 'r_max', r_max, 'r_delta', 1); 
            if length(radii)<input.number_interp
                radii_interp = linspace(0, r_max, input.number_interp);
                values_interp = interp1(radii, values, radii_interp);
            else
                radii_interp = radii;
                values_interp = values;
            end
            
            idx = find(values_interp<max(values_interp)/2, 1, 'first');
            
            if isempty(idx)
                val(ii,jj) = NaN;
            else
                val(ii,jj) = radii_interp(idx);
            end
            
%             plot(radii, values, '-', radii_interp, values_interp, ':');
            
        end
    end
    
    val = val*2; % convert half-width at half-maximum to FWHM

end