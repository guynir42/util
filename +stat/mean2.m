function y = mean2(x)
% calculates the mean across images (not including NaN!). 
% can handle 3D matrices (or higher dim), returns a vector in 3D of the
% means of each image. 

    if nargin==0
        help('util.stat.mean2');
        return;
    end

    y = nanmean(nanmean(x));
    
end