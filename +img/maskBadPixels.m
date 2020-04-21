function [image_reduced, mask] = maskBadPixels(image, filler, sigma, saturation)
% usage: [image_reduced, mask] = maskBadPixels(image, filler=median2, sigma=3, saturation=50000)
% Removes very bright (or very negative) pixels from an image. 
% Checks if each pixel is greater than <sigma> times the average of the 8
% nearest neighboors. Can handle 3D or 4D (but in loops...). 
%
% OPTIONAL PARAMETERS: 
%   -filler: which value to replace bad pixels. Default is image median. 
%   -sigma (=3) is how many times above average counts as a bad pixel.
%   
% OUTPUTS: the image after reduction, mask of 1's for bad pixels.

    import util.img.maskBadPixels;
    import util.stat.median2;
    
    if nargin==0, help('util.img.maskBadPixels'); return; end    
    if nargin<2, filler = []; end
    if nargin<3 || isempty(sigma), sigma = 5; end
    if nargin<4 || isempty(saturation), saturation = 50000; end
    
    if size(image,4)>1 % handle 4D matrices
        
        image_reduced = zeros(size(image), 'like', image);
        mask = false(size(image));
        for ii = 1:size(image,4)
            [image_reduced(:,:,:,ii), mask(:,:,:,ii)] = maskBadPixels(image(:,:,:,ii), filler, sigma);
        end
        
        return;
        
    end
    
    if size(image,3)>1 % handle 3D matrices
        
        image_reduced = zeros(size(image), 'like', image);
        mask = false(size(image));
        for ii = 1:size(image,3)
            [image_reduced(:,:,ii), mask(:,:,ii)] = maskBadPixels(image(:,:,ii), filler, sigma);
        end
        
        return;
        
    end
    
    % default is median2 of the image
    if isempty(filler)
        filler = median2(image);
    end
    
    ker = ones(3)./8;
    ker(2,2) = 0; % nearest neighbors kernel
    image_conv = filter2(ker, double(abs(image)));
    
    mask = logical( abs(double(image))>abs(sigma.*(image_conv)) );
    
    if ~isempty(saturation)
        mask = mask | image>saturation;
    end
    
    image_reduced = image;
    image_reduced(mask) = filler;

end

