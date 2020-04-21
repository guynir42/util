function S = corner_var(img, num_pix)
% usage: corner_var(img, num_pix=0.15*size(img))
% calculates the variance of the pixels in the corner of the image.
% the number of pixels by default is 15% of the size of image. 
% handles 3D and 4D matrices.

    if ~isa(img, 'single') % single precision is fine, no need to convert
        img = double(img);
    end

    if nargin==0
        help('util.stat.corner_var');
        return;
    end
    
    if nargin<2 || isempty(num_pix)
        num_pix = 0.15;
    end
    
    if num_pix>0 && num_pix<=1 
        num_pix = ceil(min(size(img, 1), size(img,2))*num_pix);
    end
    
    if num_pix>=size(img,1)
        num_pix = size(img,1)-1;
    end
    
    if num_pix>=size(img,2)
        num_pix = size(img,2)-1;
    end
    
    S = mean(nanvar(img(1:num_pix,1:num_pix,:,:))) + ...
        mean(nanvar(img(1:num_pix,end-num_pix:end,:,:))) + ...
        mean(nanvar(img(end-num_pix:end,1:num_pix,:,:))) + ...
        mean(nanvar(img(end-num_pix:end,end-num_pix:end,:,:)));

    S = S/4;

end