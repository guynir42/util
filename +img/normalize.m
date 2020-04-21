function [I, M, V] = normalize(I, varargin)
% Usage: [I, M, V] = normalize(I, varargin)
% Output a normalized image, after doing some preprocessing: 
% (a) remove bad pixels using "maskBadPixels"
% (b) remove saturated stars using "remove_saturated"
% (c) subtract bias and divide by the standard deviation from "im_stats". 
% 
% OPTIONAL ARGUMENTS
%   *All optional arguments are passed as-is to im_stats and remove_saturated
%   *Note: remove_saturated gets a default threshold which is mean+5*std 
%   where mean/std are derived from im_stats. 

    if nargin==0, help('util.img.normalize'); return; end

    I = util.img.maskBadPixels(I, NaN);
    
    [M,V] = util.img.im_stats(I, varargin{:});
    
    I = util.img.remove_saturated(I, 'threshold', M+5*sqrt(V), varargin{:}); 

    I = (I-M)./sqrt(V);
    
end