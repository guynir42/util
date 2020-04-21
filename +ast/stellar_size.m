function sizes = stellar_size(bol_mag, temp_eff, varargin)
% Usage: R_FSU = stellar_size(bol_mag, temp_eff, varargin)
% Get the estimated size (in radians, micro-arcsec or other units) for all 
% the stars given their bolometric magnitude and effective temperature. 
%
% Basically it skips over the actual distance and luminosity of the star. 
%
% OPTIONAL ARGUMENTS:
%   -units: can be radians (default), arcsec, mas, uas (micro arcsec),  
%           degrees, or Fresnel scale (see wavelength and distance). 
%   -wavelength: to calculate the stellar size in Fresnel units, must input 
%                the central wavelength in nanometers. 
%   -distance: to calculate the stellar size in Fresnel units, must input 
%              the distance to occulter in parsecs. 
%   
%           

    import util.text.cs; 

    if nargin==0, help('util.ast.stellar_size'); return; end
    
    input = util.text.InputVars;
    input.input_var('units', 'rad'); % can choose rad, degrees, arcsec, mas, uas (micro arcsec) or fsu (Fresnel scale units)
    input.input_var('wavelength', 550); % in nm (only used for calculating size in FSU)
    input.input_var('distance', 10); % in pc (only used for calculating size in FSU)
    input.scan_vars(varargin{:});
    
    % sun is used as reference:
    R_sun = 700000; % km
    M_sun = 4.83; % absolute magnitude
    T_sun = 5780; % Kelvin
    pc = 3.086e+13; % convert parsec to km
    
    % the area ratio depends on mag like 10^((M1-M2)/2.5)
    % and on temp like (T2/T1)^4. 
    % Radius is sqrt of that:
    R_km = R_sun .* 10.^((M_sun-bol_mag)./5) .* (T_sun./temp_eff).^2; 
    
    sizes = R_km ./ (10*pc); % assume this size is calculated for a star at 10 pc
    
    if cs(input.units, 'radians', 'rads')
        % pass
    elseif cs(input.units, 'degrees')
        sizes = sizes./pi.*180;
    elseif cs(input.units, 'arcsec', 'as')
        sizes = sizes./pi.*180*3600;
    elseif cs(input.units, 'milli arcsec', 'mas')
        sizes = sizes./pi.*180*3600*1000;
    elseif cs(input.units, 'micro arcsec', 'uas')
        sizes = sizes./pi.*180*3600*1e6;
    elseif cs(input.units, 'fsu', 'fresnel scale')
        FS = sqrt(input.wavelength.*1e-12./(input.distance.*pc)/2); 
        sizes = sizes./FS;
    else
        error('Unknown "units" option: "%s". Use "rad", "degrees", "arcsec", "mas", "uas", or "fsu".', input.units); 
    end
    
    
end