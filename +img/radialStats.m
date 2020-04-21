function [values, radii] = radialStats(M, func, varargin)
% Usage: [values, radii] = radialStats(M, func, varargin)
% Run annulusPixels on all radii in M, do a function on the pixels or give
% them back as a cell array. 
% If func= "cell" will give the pixel values. 
% Can choose any function with one input (std, var, mean, max, min...).
% 
% OPTIONAL ARGUMENTS:
%   -r_delta: how many pixels is the width of each annulus (default 2).  
%   -r_min: minimal radius in pixels to start calculations (default 3). 
%   -r_max: maximum radius in pixels for the biggest annulus (the default 
%           is half the image size, so basically the largest annulus you 
%           can fit in the image). 
%   -edges: check if to include the pixels along the edges of each quadrant. 
%           If zero, no edge pixels are taken. 
%           If one, only leading edge is taken (default). 
%           If two, both edges are taken. 
%   -quadrants: which quadrants of the data should be used (useful if there
%               is a known source in some quadrants that should be ignored. 
%               Input quadrants as a 4 element vector with zeros and ones. 
%               See annulusPixels for how this is sectioned. 
%
% OUTPUTS: 
%   -values: the result of the function on each annulus (e.g., mean) or the
%            values in a cell array (if func="cell"). 
%            The length of this output is equal to the number of annuli. 
%   -radii: the inner radius of each annulus (this is mostly used for plotting). 

    import util.text.cs;
    import util.img.annulusPixels;
    
    if nargin==0, help('util.img.radialStats'); return; end
    
    if nargin<2 || isempty(func)
        func = 'cell';
    end
    
    r_delta = [];
    r_min = [];
    r_max = [];
    edges = 1;
    quadrants = [1 1 1 1];
    
    for ii = 1:2:length(varargin)
    
        if cs(varargin{ii}, {'r_delta', 'dr', 'r_step'})
            r_delta = varargin{ii+1};
        elseif cs(varargin{ii}, 'r_min')
            r_min = varargin{ii+1};
        elseif cs(varargin{ii}, 'r_max')
            r_max = varargin{ii+1};
        elseif cs(varargin{ii}, 'edges')
            edges = varargin{ii+1};
        elseif cs(varargin{ii}, 'quadrants')
            quadrants = varargin{ii+1};
        end
        
    end
    
    if isempty(r_min)
        r_min = 3;
    end
    
    if isempty(r_delta)
        r_delta = 2;
    end
    
    if isempty(r_max)
        r_max = floor(min(size(M,1))/2); 
    end
    
    radii = r_min:r_delta:r_max;
    
    N = length(radii)-1;
    
    if ischar(func) && cs(func, 'cell')
        values{N} = [];
    else
        values = zeros(1, N);
    end
    
    for ii = 1:N
        
        p = annulusPixels(M, radii(ii), radii(ii+1), quadrants, edges);
        
        if ischar(func) && cs(func, 'cell')
            values{ii} = p;
        else
            values(ii) = feval(func, p);
        end
        
    end
    
    radii = radii(1:end-1);
    