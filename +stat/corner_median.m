function M = corner_median(img, num_pix)
% usage: M = corner_median(img, num_pix=0.15*size(img))
% calculates the median of the pixels in the corner of the image.
% the number of pixels by default is 15% of the size of image. 
% handles 3D and 4D matrices.
    
    if nargin==0
        help('util.stat.corner_median');
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

    values1 = img(1:num_pix,1:num_pix,:,:);
    values2 = img(1:num_pix,end-num_pix:end,:,:);
    values3 = img(end-num_pix:end,1:num_pix,:,:);
    values4 = img(end-num_pix:end,end-num_pix:end,:,:);

    values = [values1, values2; values3, values4];
    
    M = util.stat.median2(values);
    
%     M = median([values1(:); values2(:); values3(:); values4(:)], 'omitnan');

end