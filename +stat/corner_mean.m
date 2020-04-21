function M = corner_mean(img, num_pix)
% usage: M = corner_mean(img, num_pix=0.15*size(img))
% calculates the mean of the pixels in the corner of the image.
% the number of pixels by default is 15% of the size of image. 
% handles 3D and 4D matrices.

    import util.stat.mean2;
    
    if nargin==0
        help('util.stat.corner_mean');
        return;
    end

    if nargin<2 || isempty(num_pix)
        num_pix = 0.15;
    end
    
    if num_pix>0 && num_pix<=1 
        num_pix = ceil(min(size(img, 1), size(img,2))*num_pix);
    end

    if num_pix<=0
        M = 0;
        return;
    end

    if ~isa(img, 'single') % single precision is fine, no need to convert
        img = double(img);
    end

    if num_pix>=size(img,1)
        num_pix = size(img,1)-1;
    end
    
    if num_pix>=size(img,2)
        num_pix = size(img,2)-1;
    end
    
    M = mean2(img(1:num_pix,1:num_pix,:,:)) + ...
        mean2(img(1:num_pix,end-num_pix:end,:,:)) + ...
        mean2(img(end-num_pix:end,1:num_pix,:,:)) + ...
        mean2(img(end-num_pix:end,end-num_pix:end,:,:));

    M = M/4;

end