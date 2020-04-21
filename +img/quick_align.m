function [Im_new_shifted, shift, confidence] = quick_align(Im_ref, Im_new, varargin)
% Usage: [Im_new_shifted, shift, confidence] = quick_align(Im_ref, Im_new, varargin)
% Reposition the new image to be aligned with the old image, using star positions. 
%
% Takes the max of rows and columns for each image, representing the positions
% of the brightest stars, then cross correlates them in X and Y to find the 
% best alignement between the images. 
%
% INPUTS: Im_ref and Im_new are the two images to be aligned. New is moved to ref. 
%
% OPTIONAL ARGUMENTS:
%   -static: if true, do not shift the new image, return it as-is, and just 
%            report the required shift between the two images as 2nd output.
%   -flip: return shift as X then Y (default true). 
%
% OUTPUTS: 
%   -Im_new_shifted: the new image, shifted to match the reference. 
%                    Uses util.img.imshift to do the moving and padding. 
%   -shift: what is the shift, in pixels, between the images (when flip option
%           is given, which is the default, returns X then Y elements). 
%   -confidence: how good the match between the images is. To be added later,
%                in this version confidence is always zero! 
%
%

    import util.img.pad2size;
    
    if nargin==0, help('util.img.quick_align'); return; end
    
    input = util.text.InputVars;
    input.input_var('static', false);
    input.input_var('flip', false);
    input.scan_vars(varargin{:});
    
%     Rx = sum(Im_ref,1)';
%     Ry = sum(Im_ref,2);
%     Nx = sum(Im_new,1)';
%     Ny = sum(Im_new,2);    
    Rx = max(Im_ref,[],1)';
    Ry = max(Im_ref,[],2);
    Nx = max(Im_new,[],1)';
    Ny = max(Im_new,[],2);
    
    Rx = Rx-median(Rx);
    Ry = Ry-median(Ry);
    Nx = Nx-median(Nx);
    Ny = Ny-median(Ny);
    
    Rx = pad2size(Rx, size(Nx));
    Nx = pad2size(Nx, size(Rx));
    Ry = pad2size(Ry, size(Ny));
    Ny = pad2size(Ny, size(Ry));
    
%     Rx = pad2size(Rx, [2*size(Rx,1),1]);
%     Nx = pad2size(Nx, [2*size(Nx,1),1]);
%     Ry = pad2size(Ry, [2*size(Ry,1),1]);
%     Ny = pad2size(Ny, [2*size(Ny,1),1]);
    
    xcorr = fftshift(ifft(conj(fft(fftshift(Rx))).*fft(fftshift(Nx))));
    [mxx, idx] = max(xcorr);
    center_x = floor(length(Rx)/2)+1;
    idx = idx - center_x;
    mnx = mean(xcorr);
    sdx = std(xcorr);
    
    ycorr = fftshift(ifft(conj(fft(Ry)).*fft(Ny)));
    [mxy, idy] = max(ycorr);
    center_y = floor(length(Ry)/2)+1;
    idy = idy - center_y;
    mny = mean(ycorr);
    sdy = std(ycorr);
    
%     plot(xcorr);
%     hold on;
%     plot(ycorr);
%     hold off;
%     drawnow;
    
    % calculate confidence (to be added later)
    confidence = 0;
    
    shift = -[idy idx];
    
    if input.static
        Im_new_shifted = Im_new;
    else
        Im_new_shifted = util.img.imshift(Im_new, shift(1), shift(2));
    end
    
    if input.flip
        shift = flip(shift);
    end
    
end