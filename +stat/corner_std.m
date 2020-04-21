function S = corner_std(img, num_pix)
% usage: corner_std(img, num_pix=0.15*size(img))
% calculates the standard deviation of the pixels in the corner of the image.
% the number of pixels by default is 15% of the size of image. 
% handles 3D and 4D matrices.
% based on the util.stat.corner_var function. 
    
    import util.stat.corner_var;

    if nargin==0
        help('util.stat.corner_std');
        return;
    end
    
    if nargin<2
        num_pix = [];
    end
    
    S = sqrt(corner_var(img, num_pix));

end