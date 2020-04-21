function [dynamic_range_vector, image_reduced] = autodyn(image, filler, sigma, saturation)
% usage: [dynamic_range_vector, image_reduced] = autodyn(image, filler=median)
% Uses "maskBadPixels" to remove outliers in the image and then returns the
% dynamic range [min max] values in the image. Should be used to set CLim
% for images to get a better look. 
% Returns as optional second output the reduced image. 
% The option "filler" chooses what to fill the bad pixels. 
% The option "sigma" chooses how much stronger than average counts as bad.
% Both are [] by default, which uses the default in maskBadPixels
% (filler default is image median, sigma is 3).

    import util.img.maskBadPixels;
    import util.stat.median2;
    import util.stat.std2;

    if nargin==0, help('util.img.autodyn'); return; end
    
    if nargin<2 || isempty(filler)
        filler = [];
    end
    
    if nargin<3 || isempty(sigma)
        sigma = [];
    end
    
    if nargin<4 || isempty(saturation)
        saturation = [];
    end
    
%     image_reduced = image;
    
    image_reduced = maskBadPixels(image, filler, sigma, saturation);

%     ker = ones(3)./8;
%     ker(2,2) = 0;
%     
%     image_reduced = conv2(double(image_reduced), ker, 'valid');
    
    % dynamic_range_vector(1) = min2(image_reduced);
    % dynamic_range_vector(2) = max2(image_reduced);
    
    M = median2(image_reduced);
    S = std2(image_reduced);
    
    dynamic_range_vector(1) = util.stat.min2(squeeze(double(M)-S));
    dynamic_range_vector(2) = util.stat.max2(squeeze(double(M)+10*S));
    
end