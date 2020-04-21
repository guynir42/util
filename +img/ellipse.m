function I = ellipse(varargin)
% usage: I = ellipse(a, dx=0, dy=0, e=0, rot_frac=0, S=auto, norm=0)
% Generates an image of an ellipse with fractional pixels on the edges. 
%
% PARAMETERS:
%   -a (or R): semi-major axis of the ellipse (or radius of a circle)
%   -x_shift: move the center of the Gaussian in the x direction.
%   -y_shift: move the center of the Gaussian in the y direction.
%   -e: eccentricity of the ellipse (default=0 for circle, max is 1).
%       NOTE: the semi-minor axis is b = a*sqrt(1-e^2).
%   -rot_frac: rotation angle in units of 0 to 1 (=90 degrees). 
%   -hole: create a circular hole to make it an annulus (default is 0). 
%   -S: size of image (assumed square). Default is 2*a+1,
%       adjusted to be an odd-number.
%   -norm: choose normalization option. 
%          norm=0: not normalized (ellipse surface is 1);
%          norm=1: the sum of the shape is 1. 
%          norm=2: the sqrt of sum of squares of the shape is 1. 
%
% Parameters can be given in order or as keyword-value pairs...

    if nargin==0, help('util.img.ellipse'); return; end

    input = util.text.InputVars;
    input.input_var('a', [], 'R', 'radius', 'semi major axis');
    input.input_var('dx', 0, 'x_shift');
    input.input_var('dy', 0, 'y_shift');
    input.input_var('e', 0, 'eccentricity');
    input.input_var('rot_frac', 0);
    input.input_var('hole', 0, 'inner_radius');
    input.input_var('S', [], 'size', 'imsize');
    input.input_var('oversampling', 1);
    input.input_var('norm', 0, 'normalization');
    input.use_ordered_numeric = 1;
    input.scan_vars(varargin{:});
    
    if isempty(input.a)
        error('Must supply a radius/semi-major axis');
    end
    
    if input.e<0 || input.e>1
        error('This function only handles eccentricity in the range 0<e<1. Received e= %f', input.e);
    end
    
    if input.hole>input.a
        error('Inner radius of annulus r=%f is bigger than semi-major axis a= %f', input.hole, input.a);
    end
    
    if isempty(input.S)
        input.S = 2.*input.a + 1;
        input.S = input.S+mod(input.S+1,2); % make sure it is an odd number
    end
    
    if input.oversampling
        S = input.oversampling.*input.S;
        a = input.oversampling.*input.a;
        dx = input.oversampling.*input.dx;
        dy = input.oversampling.*input.dy;
        r = input.oversampling.*input.hole;
    else
        S = input.S;
        a = input.a;
        dx = input.dx;
        dy = input.dy;
        r = input.hole;
    end
    
    [x,y] = meshgrid(-floor((S)/2):floor((S-1)/2));
    
    % rotate the coordinates
    if isempty(input.rot_frac)
        x2 = x;
        y2 = y;
    else
        x2 = +x*cos(pi/2*input.rot_frac)+y*sin(pi/2*input.rot_frac);
        y2 = -x*sin(pi/2*input.rot_frac)+y*cos(pi/2*input.rot_frac);
    end
    
    % shift the coordinates
    if ~isempty(input.dx)
        x2 = x2 - dx;
    end
    
    if ~isempty(input.dy)
        y2 = y2 - dy;
    end
    
    b = a*sqrt(1-input.e.^2);
    
    I = double((x2./a).^2 + (y2./b).^2 < 1);
    
    if input.hole>0
        I(x2.^2+dy.^2<r) = 0;
    end
    
    if input.oversampling
        I = util.img.downsample(I, input.oversampling, 'mean');
    end
    
    if input.norm==1
        I = I./util.stat.sum2(I);
    elseif input.norm==2
        I = I./sqrt(util.stat.sum2(I.^2));
    end
    
end