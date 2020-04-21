function f_out = zero_point_correct(f, varargin)
% Usage: f_out = zero_point_correct(f, varargin)
% Apply zero point correction to a lightcurve. The fluxes must be in along 
% the first dimension, the different stars should be in the second. 
%
% Optional arguments:
% 
% Output: The corrected fluxes. 

    if nargin==0, help('util.series.zero_point_correct'); return; end
    
    F = nanmean(f,2); % get the average flux per epoch. 
    T = F./nanmean(F,1); % get the relative transparency (zero point) in each epoch. 
    
    f_out = f./T; % correct the flux

    
    
end