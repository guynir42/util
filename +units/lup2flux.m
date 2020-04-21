function f = lup2flux(mag, b)
% Usage: f = lup2flux(mag, b)
% Transform luptitudes back to fluxes. Must specify the softening parameter 
% "b" for this to work. It is generally equal to the 1-sigma noise level, 
% but this value really needs to be recorded when transforming into luptitudes
% in the first place. 
%
% See the help section for flux2lup() for more details. 

    if nargin==0, help('util.units.lup2flux'); return; end
    
    a = 2.5*log10(exp(1)); % Pogson's ratio
    
    f = -2.*b.*sinh(mag./a + log(b));

    
end