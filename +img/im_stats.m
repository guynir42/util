function [M,V] = im_stats(Im, varargin)
% Usage: [M,V] = im_stats(Im, varargin)
% Gets basic statistics on a 2D image by cutting it into smaller tiles
% (using "jigsaw" function) and calculating the average median and variance
% values. This is a quick and dirty way to estimate the background and
% noise in an image even if it has stars in it. 
% 
% OPTIONAL ARGUMENTS:
%   *So far there are no optional arguments. 
%   *The arguments given are passed to "jigsaw" (e.g., tile size, padding).
% 
    
    if nargin==0, help('util.img.im_stats'); return; end

    C = util.img.jigsaw(Im, varargin{:}); % get cutouts
    
    M = median(util.stat.median2(C), 'omitnan');
    V = median(util.stat.var2(C), 'omitnan');

end