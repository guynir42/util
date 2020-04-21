function [f_det, a, c, stats] = sysrem(f, varargin)
% Usage: [f_det, a, c, stats] = sysrem(f, varargin)
% Apply the Tamuz et al. 2005 Sys-Rem detrending on fluxes 'f'. 
% Assumes the time axis is the first dimension of 'f' and the different 
% stars are on the second dimension. 
%
% Iteratively find the best a_j ("airmass") for each frame and best c_i 
% (coefficient) for each star, that minimize the rms of r_ij-a_j*c_i
% (r_ij are the residuals after subtracting the mean of f for each frame j 
% and each star i). 
% 
% OUTPUTS: -'f_det' is the detrended fluxes (same size as f). 
%          -'a' and 'c' are the coefficients that were subtracted. 
%          -'stats' contains statistics on the Sys-Rem process. 
%           (currently this is empty, we need to finish that)
% 
% OPTIONAL ARGUMENTS:
%   -errors: input the error per star, or per frame, or a 2D matrix for all. 
%            The default is to set all errors to one. 
%   -a: input an initial guess for the a-vector, e.g., the airmass. 
%       The default is to calculate it using uniform c-vector or by the 
%       c-vector given as optional input. 
%   -c: input an initial guess for the c-vector, e.g., the color coefficients. 
%       The default is to estimate this after getting the a-vector or by 
%       first calculating the a-vector assuming uniform c-vector. 
%   -iterations: how many criss crossings to find a and c, after finding the
%                initial guesses for them . Default 1. 
%
%   -magnitudes: the fluxes given are already in units of magnitudes. 
%                If false (default), will convert to magnitudes. 
%
%   -luptitudes: Use asinh units instead of logarithmic (default true). 
%                
%   -pedestal: add a constant to all fluxes before converting to magnitudes. 
%              Prevents negative values. Default is true. 
%
%   -subtract: remove the mean value of the magnitudes of each star's flux. 
%              Default is true. Set to false if you already subtracted it. 
%
%   -stars: set some stars as "black list", so they are not used in the 
%           calculation of the a-vector. They are still calibrated by other
%           stars! Default is [], so use all stars. 
%
%   -self_exclude: make sure each star has a different a-vector, that does 
%                  not include itself in its a-vector calculation. 
%                  This increases the runtime but makes sure Sys-Rem does 
%                  not destroy actual signal that is found in the star's flux. 
%                  Default is false. 
%
%   -fft: use FFT on the magnitudes before running Sys-Rem. In this case
%         the flux is adjusted for each frequency instead of each epoch. 
%         This produces a complex c-vector but the a-vector is kept real 
%         using abs(), so it does not mix the phases in each lightcurve. 
% 


    if nargin==0, help('util.series.sysrem'); return; end
    
    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('errors', [], 'sigma'); % error on each flux measurement, (use vector/scalar to mark errors per frame/per star/global error)
    input.input_var('a', [], 'airmass'); % already have a good initial guess for the 'a' vector
    input.input_var('c', [], 'coeffs', 'coefficients'); % already have a good inital guess for the 'c' vector\
    input.input_var('iterations', 1, 'num_iterations'); % how many times to 'criss-cross' the coefficients 'a' and 'c' after the inital guess
    input.input_var('luptitudes', true); % use luptitudes instead of magnitudes. Ignored if "magnitudes" is true. 
    input.input_var('magnitudes', false); % assume input is given as magnitudes, with negative values taken care of
    input.input_var('pedestal', true, 'use_pedestal', 'constant'); % add some constant to each flux measurement before turning it into magnitudes (instead of putting NaN in negative values)
    input.input_var('subtract', true, 'subtract_mean', 'use_subtract_mean', 'use_mean', 'mean'); % if true, will remove the mean of each flux f_ij to get residual r_ij
    input.input_var('stars', [], 'star_black_list'); % which stars should be avoided when calculating 'a'
    input.input_var('self', false, 'self_exclude', 'use_self_exclude'); % remove each star from the calculation of its own a-vector
    input.input_var('fft', false, 'fourier'); % run Sys-Rem on frequencies instead of epochs
    input.scan_vars(varargin{:}); 
    
    if isempty(input.stars)
        input.stars = false(1, size(f,2)); 
    end
    
    if input.magnitudes
        m = f;
    else
        
        if input.luptitudes

            A = 2.5*log10(exp(1)); % Pogson's ratio
            
            % the softening parameter b is chosen to be the mininmal error in the system
            if isempty(input.errors)
                e = nanstd(f(:,~input.stars)); 
            else
                e = nanmean(input.errors, 1); 
            end
            
            b = nanmin(e); % the least error of all stars
            
            m = -A.*(asinh(f./2./b) + log(b));
            
        elseif input.pedestal
            P = util.stat.min2(f)*2; 
            if P<0
                P = -P;
            else
                P = 0;
            end
            m = -2.5.*log10(f+P);         
        else
            P = 0;
            f(f<=0) = NaN;
            m = -2.5.*log10(f); 
%             m = asinh(f); 
        end
        
        if ~isempty(input.errors) % errors are given on the flux, not on the magnitudes! 
            input.errors = input.errors./abs(nanmean(f,1)); % translate flux errors to mag errors (approximation of 2.5 to e)
        end
        
    end
    
    if isempty(input.errors)
        input.errors = ones(size(m), 'like', m); % uniform errors! 
    end
    
    if input.subtract
        M = nanmean(m,1); 
        r = m - M;
    else
        M = 0;
        r = m;
    end
    
    input.errors(input.errors==0) = Inf;
    input.errors(:,input.stars) = Inf; % any bad stars on the black list will have Inf errors and won't count for anything
    
    if input.fft
        r = fft(fillmissing(r, 'linear')); 
    end
    
    %%%%%%%    input parsing and unit conversions are done    %%%%%%%%
    
    if isempty(input.a) && isempty(input.c) % no 'a' or 'c' given, do a preliminary calculation to get both
        c = ones(1, size(f,2), 'like', f); % assume all stars have the same response coefficient! 
        a = calculateAirmass(r, input.errors, c, input.self, input.fft); 
        c = calculateColors(r, input.errors, a); 
    elseif isempty(input.a) % only 'a' is empty, use 'c' to find 'a'
        c = input.c;
        a = calculateAirmass(r, input.errors, c, input.self, input.fft); 
    elseif isempty(input.c) % only 'c' is empty, use 'a' to find 'c' (this can happen if 'a' is given by airmass)
        a = input.a;
        c = calculateColors(r, input.errors, a); % sum over 'j' is sum over frames
    else
        a = input.a;
        c = input.c;
    end
    
    for ii = 1:input.iterations
        a = calculateAirmass(r, input.errors, c, input.self, input.fft); 
        c = calculateColors(r, input.errors, a); 
    end
    
    r_new = r - a.*c;
    
    if input.fft
        r_new = real(ifft(r_new)); 
    end
    
    m_det = r_new + M; 
    
    if input.magnitudes==0
    
        if input.luptitudes
            f_det = -2.*b.*sinh(m_det./A + log(b));
        else
            f_det = 10.^(-0.4.*m_det) - P; % use classical magnitudes, possibly with a pedestal P
        end
    
    else
        f_det = m_det; % return magnitudes, as given
    end

    stats = [];
    
end

function a = calculateAirmass(residuals, errors, c, use_self_exclude, use_fft) % sum over 'i' is sum over stars
    
    p1 = residuals.*c./errors.^2; % product 1
    s1 = nansum(p1, 2); % sum 1
    
    p2 = c.^2./errors.^2; % product 2
    s2 = nansum(p2, 2); % sum 2 
    
    if use_self_exclude % remove from each sum the contribution of one star, turning it from a vector to a matrix
        s1 = s1 - p1; 
        s2 = s2 - p2; 
    end
    
    a = s1./s2; 
    
    if use_fft
        a = abs(a); 
    end
    
end

function c = calculateColors(residuals, errors, a) % sum over 'j' is sum over frames
    
    c = nansum(residuals.*a./errors.^2, 1)./nansum(a.^2./errors.^2, 1); 

end

