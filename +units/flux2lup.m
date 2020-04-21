function [M, b] = flux2lup(flux, b)
% Usage: [M, b] = flux2lup(flux, b)
% Turn flux measurements into Luptitudes (inverse sine magnitudes). 
% These are similar to regular magnitudes, but close to zero flux
% They behave linearly instead of logarithmically. 
% This handles zero and negative fluxes rather gracefully. 
% The second input "b" is the softening parameter, that should be close
% to the flux noise level ("one sigma"). 
% If it is left empty, we use the median value of the std of each flux. 
%
% Ref paper: 

    if nargin==0, help('util.units.flux2lup'); return; end
    
    if nargin<2 || isempty(b)
        S = nanstd(flux, [], 1);
        b = nanmedian(S(:)); 
    end

    a = 2.5*log10(exp(1)); % Pogson's ratio

    M = -a.*(asinh(flux./2./b) + log(b));
    
end