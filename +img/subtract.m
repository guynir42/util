function [D, PD, FD, shift, ratio] = subtract(varargin)
% Usage: [D, PD, FD, shift, ratio] = subtract(M1,P1,M2,P2,F1=1,F2=1,sig1=1,sig2=1,align=0,match_flux=0)
% Applies ZOGY proper image subtraction. 
% INPUTS: the first 4 inputs are mandatory, the rest have reasonable defaults. 
%         The inputs are all named, so if you don't want to give them in order,
%         simply input them as keyword-value pairs. 
%   -M1 and M2 are the images to be subtracted, i.e., D=M2-M1
%   -P1 and P2 are the respective PSFs (point spread functions). 
%   -F1 and F2 are the relative flux or transparency of each image. 
%   -sig1 and sig2 are the image noise rms (can be scalar or map the size of M). 
%
% These are still experimental at this point:
%   -align: use subpixel shifts to get the smallest residuals after subtractions.
%   -match_flux: use rescaling of M2 to M1 to get the smallest residuals.

    import util.img.pad2size;
    import util.fft.fftshift2;

    if nargin==0, help('util.img.subtract'); return; end
    
    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('M1', [], 'image1', 'ref_image');
    input.input_var('P1', [], 'psf1', 'ref_psf');
    input.input_var('M2', [], 'image2', 'new_image');
    input.input_var('P2', [], 'psf2', 'new_psf');
    input.input_var('F1', 1, 'flux1', 'ref_flux');
    input.input_var('sig1', 1, 'noise1', 'sigma1', 'ref_noise', 'ref_sigma');
    input.input_var('F2', 1, 'flux2', 'new_flux');
    input.input_var('sig2', 1, 'noise2', 'sigma2', 'new_noise', 'new_sigma');
    input.input_var('align', false, 'subpixel');
    input.input_var('match_flux', false);
    input.scan_vars(varargin{:});
    
    if isempty(input.M1) || isempty(input.P1) || isempty(input.M2) || isempty(input.P2)
        error('Cannot do subtraction without M1,M2,P1,P2!');
    end
    
    input.M1 = pad2size(input.M1, size(input.M2));
    input.M2 = pad2size(input.M2, size(input.M1));
        
    M1f = fftshift2(fft2(fftshift2(input.M1)));
    M2f = fftshift2(fft2(fftshift2(input.M2)));
    P1f = fftshift2(fft2(fftshift2(pad2size(input.P1,size(input.M1)))));
    P2f = fftshift2(fft2(fftshift2(pad2size(input.P2,size(input.M2)))));
    
    if input.align==0 && input.match_flux==0
        [Df, PDf, FDf] = simpleSubtraction(M1f, P1f, input.F1, input.sig1, M2f, P2f, input.F2, input.sig1);
        shift = [0 0];
        ratio = 1;
    elseif input.align==1 && input.match_flux==0
        [Df, PDf, FDf, shift] = alignSubtraction(M1f, P1f, input.F1, input.sig1, M2f, P2f, input.F2, input.sig1);
        ratio = 1;
    elseif input.align==0 && input.match_flux==1
        [Df, PDf, FDf, ratio] = matchSubtraction(M1f, P1f, input.F1, input.sig1, M2f, P2f, input.F2, input.sig1);
        shift = [0 0];
    elseif input.align==1 && input.match_flux==1
        [Df, PDf, FDf, shift, ratio] = matchAlignSubtraction(M1f, P1f, input.F1, input.sig1, M2f, P2f, input.F2, input.sig1);
    end
    
    D = fftshift2(ifft2(fftshift2(Df)));
    
    if nargout>1
        PD = fftshift2(ifft2(fftshift2(PDf)));
    end
    
    if nargout>2
        FD = fftshift2(ifft2(fftshift2(FDf)));
    end
    
end

function [D, PD, FD] = simpleSubtraction(M1, P1, F1, sig1, M2, P2, F2, sig2)

    denom = sqrt(sig2.^2.*F1.^2.*abs(P1).^2 + sig1.^2.*F2.^2.*abs(P2).^2);
    
    D = (F1.*P1.*M2-F2.*P2.*M1)./denom;
    
    FD = F1.*F1./sqrt((sig1.*F2).^2 + (sig2.*F1).^2);
    
    PD = F1.*F2.*P1.*P2./denom./FD;
    
end

function [D, PD, FD, shift] = alignSubtraction(M1, P1, F1, sig1, M2, P2, F2, sig2)
    
    shift = [0 0];
    
    func = @(b) alignHelper(b,M1, P1, F1, sig1, M2, P2, F2, sig2);
    
    shift = fminsearch(func, shift); 
    
    [D, PD, FD] = simpleSubtraction(M1, P1, F1, sig1, shiftImage(M2,shift), P2, F2, sig2);
    
end

function sum_res = alignHelper(b, M1, P1, F1, sig1, M2, P2, F2, sig2)

    % b is the shift in x then in y
    M2 = shiftImage(M2, b);

    D = simpleSubtraction(M1, P1, F1, sig1, M2, P2, F2, sig2);
    
%     util.plot.show(D);
%     drawnow;
%     disp(['shift= ' num2str(b)]);
    
    sum_res = util.stat.sum2(abs(D));
    
end

function M = shiftImage(M, shift)

    S = size(M);
    M = M.*exp(-1i.*2.*pi.*(-floor(S(2)/2):floor((S(2)-1)/2))./S(2).*shift(1)); % shift in x
    M = M.*exp(-1i.*2.*pi.*(-floor(S(1)/2):floor((S(1)-1)/2))'./S(1).*shift(2)); % shift in y
    
end


