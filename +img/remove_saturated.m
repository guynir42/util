function [I_out, mask, cc] = remove_saturated(I, varargin)
% usage: [I_out, mask, cc] = remove_saturated(I, varargin)
% Removes the saturated stars in an image I. 
%
% OPTIONAL ARGUMENTS:
%  *saturation: pixels above this level are considered saturated. Default: 45000. 
%  *replace: this value is placed instead of saturated stars. Default is NaN (or zero for integer types). 
%  *connected: remove all pixels connected to the saturated pixel (default: 1). 
%  *threshold: pixels above this are considered ON for the connection map. 
%              Default is 5. It assumes the image is normalized to an S/N map. 
%  *expand: remove pixels around found saturated stars using imdilate. 
%           Default is 1, but can be higher number (size of dilation operator). 
%
% 

    if nargin==0, help('util.img.remove_saturated'); return; end
    
    if ~ismatrix(I), error('Must input a 2D matrix!'); end
    
    input = util.text.InputVars;
    input.input_var('saturation', 45000, 'saturated');
    input.input_var('replace', NaN, 'replace_value');
    input.input_var('connected', true);
    input.input_var('threshold', 5);
    input.input_var('expand', 1, 'dilate');
    input.scan_vars(varargin{:});
    
    if isnan(input.replace) && isinteger(I)
        input.replace = 0;
    end
    
    if input.connected
        
        mask = false(size(I));
        
        cc = bwconncomp(I>input.threshold); % finds all connected regions (i.e., stars/blobs above threshold)
        
        for ii = 1:cc.NumObjects
            
            if length(cc.PixelIdxList{ii})>0.5*numel(I)
                error('Connected area %d has %d points, more than half of the image size!', ii, length(cc.PixelIdxList{ii}));
            end
            
            if any(I(cc.PixelIdxList{ii})>input.saturation) % blob contains a saturated pixel
                mask(cc.PixelIdxList{ii}) = true; 
            end
            
        end
        
    else
        
        mask = I>input.saturation; 
        
    end

    if input.expand
        kernel = ones(1+input.expand*2);
        mask = imdilate(mask, kernel);
    end
    
    I_out = I;
    
    I_out(mask) = input.replace;
    
end