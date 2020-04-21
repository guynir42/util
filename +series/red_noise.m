function f = red_noise(N, amplitude, power_law)
% Usage: f = red_noise(N, amplitude=100, power_law=-2)
% Produce a timeseries with red noise. 
% Inputs: N: the length of the series (must be given)
%         amplitude: the rms at the base frequency (default 1). 
%         power_law: how the noise drops/rises with frequency (default -2)
%                    Note the power law index should usually be negative!
% 
% Output: the time series. 
%
% Note: to make the results more realistic, try adding background and source noise:
% Example: f = red_noise(1024, 100, -1);
%          F = normrnd(f, sqrt(f+1)); % added source noise and B=1 background noise. 

    if nargin==0, help('util.series.red_noise'); return; end

    if nargin<2 || isempty(amplitude)
        amplitude = 100;
    end
    
    if nargin<3 || isempty(power_law)
        power_law = -2; 
    end

    freq = (1:N)'; % number of frequencies

    mid_idx = floor(N/2) + 1;
    
    noise_spectrum = abs(amplitude*(freq - mid_idx).^power_law); 
    
    noise_spectrum(mid_idx) = amplitude;
    
    coeffs = normrnd(0, fftshift(noise_spectrum))+1i*normrnd(0, fftshift(noise_spectrum)); 
    
    f = real(fft(coeffs)); %/sqrt(length(coeffs));
    
end