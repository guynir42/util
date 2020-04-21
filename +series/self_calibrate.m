function [flux_cal, flux_smoothed] = self_calibrate(flux, varargin)
% Usage: [flux_cal, flux_smoothed] = self_calibrate(flux, varargin)
% Take fluxes from one or several sources from the same epochs and remove 
% large trends, red noise, zero point correction, etc. 
%
% Input: a 2D matrix of fluxes, dim 1 is time, dim 2 is stars. 
%         
% Outputs: -a matrix of the same size, with trends removed. 
%          -a matrix of the same size, detrended and smoothed. 
%
% OPTIONAL ARGUMENTS: (the first 2 arguments can be given without keywords)
%   -timestamps: give the epoch timing (default is just 1:num_epochs). 
%
%   -errors: give the measured rms for each epoch and for each star. 
%
%   -use_zp: use a different zero-point for each epoch. Only for multiple stars. 
%            Default is true, unless there is only a single flux vector. 
%
%   -missing: what option to use when removing NaN values, for fillmissing(). 
%             Default is "linear". 
% 
%   -use_sg: apply Savitzky Golay polynomial fit smoothing to the data before
%            running ZP correction. This is very useful for removing short
%            time-scale variations before the ZP. Default false. 
%
%   -sg_order: what order of polynomial to fit to the SG filter. Default 3. 
%
%   -sg_length: number of frames to use for the SG fit. This window represents
%               the time-scale of smoothing, where global variations have
%               more power than local, short time-scale scintillations. 
%               Default is 125 bins, equivalent to 5 seconds at W-FAST. 
%
%   -use_poly: use an Nth order polynomial to fit simultaneously to all the
%              stars' lightcurves. Each iteration uses the mean flux of each
%              lightcurve to match them to the same level and then average
%              out the fit coeffs. The average polynomial is subtracted, then
%              another iteration improves the fit. Default false.
%              NOTE: this method is currently discouraged. 
%
%   -order: highest order polynomial for the fit (default 5). 
%
%   -use_welch: apply Welch's method to calculating the power spectral density, 
%               then use it to rescale the noise at different frequencies 
%               (make it white noise). This can be applied to a single star's 
%               flux, or to multiple stars individually. Default false. 
%               NOTE: this is not yet implemented! 
%
%   -window: number of samples in the welch window. 
% 

    if nargin==0, help('util.series.self_calibrate'); return; end
    
    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('timestamps', []); 
    input.input_var('errors', []); 
    input.input_var('use_zp', true, 'zero point'); % check if we want to apply zero point (ZP) calibration across different stars in the field
    input.input_var('missing', 'linear', 'missing_method'); % how to replace the NaN values (second argument to fillmissing())
    input.input_var('use_sg', false, 'savitzky_golay', 'sgolay'); % use smoothing with Savitsky Golay filter
    input.input_var('sg_order', 3); % the SG polynomial order
    input.input_var('sg_length', 125); % the length to use for calculting the SG filter
    input.input_var('use_poly', false, 'use_polynomial', 'polynomial'); % polynomial fit to all fluxes together (this is not a good option)
    input.input_var('order', 5); % polynomial order
    input.input_var('use_welch', false, 'welch'); % reduce red noise per star using Welch's method to estimate the PSD (not yet implemented!)
    input.input_var('window', 128); % welch window size
    input.scan_vars(varargin{:}); 
    
    if isempty(input.timestamps)
        input.timestamps = 1:size(flux,1); 
    end
    
    f = flux; % temporary variable to be adjusted in each iteration
    
    ff = fillmissing(f, input.missing); % filled in the NaN values
    
    t = input.timestamps; % shorthand for the times
    
    if input.use_zp && size(f,2)>1 % only to ZP if there is more than one star! 
        
        if input.use_sg
            
            fs = sgolayfilt(double(ff), input.sg_order, input.sg_length); % smoothed fluxes using the Savitzky Golay filter
%             fs = medfilt1(ff, input.sg_length, 'omitnan'); % just trying other smoothing methods... 

        else
            fs = ff; % no smoothing, just take the fluxes as is (removed of NaNs!)
        end
        
        w = nanmean(fs); % weights are given by the average flux of each star

        f_average = nanmean(fs.*w,2); % weighted average of each frame
        f_average_norm = f_average./nanmean(f_average); % normalize by the average of averages

        f = f./f_average_norm;
        fs = fs./f_average_norm; 

    else
        fs = f;
    end
    
    if input.use_poly
        
        flog = abs(log10(f)); % abs gets rid of any complex numbers brought on by negative fluxes (there may be better ways to do this, maybe use Luptitudes?)  
        
        r = util.fit.polyfit(t, flog, 'order', input.order, 'iterations', 3, 'sigma', 3, 'double', 1); % fit each log-flux independently 

        C = [r.coeffs]; 
        M = 10.^C(1,:); % overall scaling of each star
        C = sum(M.*C,2)./sum(M,2); % get the (flux weighted) average polynomial coeffs
        C(1) = 0; % do not try to make any changes to the overall scaling of each flux
        C = C'; 

        T = ones(size(t,1),1); % construct the time axis in different powers

        for jj = 1:input.order
            T = [T t.^jj]; 
        end

        model = sum(C.*T,2); % this polynomial model represents the best fit to all fluxes

        flog = flog - model; 
       
        f = 10.^flog;
        
    end
        
    if input.use_welch
        % to be continued...
    end
    
    flux_cal = f; % make sure to output something even if all methods are false! 
    flux_smoothed = fs;
    
end