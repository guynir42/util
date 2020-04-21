function h_out = density(x, y, varargin)
% Usage: h_out = density(x, y, varargin)
% Plot the density histogram for the points given by x and y. 
%
% OPTIONAL ARGUMENTS:
%   -

    if nargin==0, help('util.plot.density'); return; end
    
    input = util.text.InputVars;
    input.input_var('log', false, 'use_log'); 
    input.input_var('ax', [], 'axes', 'axis'); 
    input.input_var('colorbar', true); 
    input.scan_vars(varargin{:}); 
    
    if isempty(input.ax)
        input.ax = gca;
    end
    
    [N, EX, EY] = histcounts2(x,y); 
    
    h = imagesc(EX(1:end-1), EY(1:end-1), N'); 
    
    if input.colorbar
        colorbar(input.ax);
    end
    
    if input.log
        input.ax.ColorScale = 'log';
    end
    
    if nargout>0
        h_out = h;
    end
    
end