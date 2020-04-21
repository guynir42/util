function I = gaussian2(varargin)
% usage: gaussian2(sigma_x,sigma_y=sigma_x,rot_frac=0,S=auto, norm=0)
% Generates an image of a 2D Gaussian at the center. 
% PARAMETERS:
%   -sigma_x: the width sigma parameter in the X direction. 
%   -sigma_y: the width sigma in Y. Default is same as X. 
%   -rot_frac: rotation angle in units of 0 to 1 (=90 degrees). 
%   -x_shift: move the center of the Gaussian in the x direction;
%   -y_shift: move the center of the Gaussian in the y direction;
%   -S: size of image (assumed square). Default is ceil(max(sigma_x,sigma_y)*10),
%       adjusted to be an odd-number.
%   -norm: choose normalization option. 
%          norm=0: not normalized (peak is 1);
%          norm=1: the sum of the Gaussian is 1. 
%          norm=2: the sqrt of sum of squares of Gaussian is 1. 
%
% Parameters can be given in order or as keyword-value pairs...

    if nargin==0, help('util.img.gaussian2'); return; end

    input = util.text.InputVars;
    input.input_var('sigma_x', [], 'CX');
    input.input_var('sigma_y', [], 'CY');
    input.input_var('x_shift', [], 'dx');
    input.input_var('y_shift', [], 'dy');
    input.input_var('rot_frac', 0);
    input.input_var('S', [], 'size', 'imsize');
    input.input_var('norm', 0, 'normalization');
    input.use_ordered_numeric = 1;
    input.scan_vars(varargin{:});
    
    if isempty(input.sigma_x) && isempty(input.sigma_y)
        error('Must supply a width of the Gaussian...');
    elseif ~isempty(input.sigma_x) && isempty(input.sigma_y)
        input.sigma_y = input.sigma_x;
    elseif isempty(input.sigma_x) && ~isempty(input.sigma_y)
        input.sigma_x = input.sigma_y;
    end
        
    if isempty(input.S)
        input.S = ceil((max(input.sigma_x, input.sigma_y)*10));
        input.S = input.S+mod(input.S+1,2);
    end
                
    [x,y] = meshgrid(-floor((input.S)/2):floor((input.S-1)/2));
    
    if isempty(input.rot_frac)
        x2 = x;
        y2 = y;
    else
        x2 = +x*cos(pi/2*input.rot_frac)+y*sin(pi/2*input.rot_frac);
        y2 = -x*sin(pi/2*input.rot_frac)+y*cos(pi/2*input.rot_frac);
    end
    
    if ~isempty(input.x_shift)
        x2 = x2 - input.x_shift;
    end
    
    if ~isempty(input.y_shift)
        y2 = y2 - input.y_shift;
    end
    
    I = exp(-0.5*((x2./input.sigma_x).^2 + (y2./input.sigma_y).^2));
    
    if input.norm==1
        I = I./util.stat.sum2(I);
    elseif input.norm==2
        I = I./sqrt(util.stat.sum2(I.^2));
    end
        
end