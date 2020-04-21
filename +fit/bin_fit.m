function [fr, h_out] = bin_fit(x, y, varargin)
% Usage: [fr, h_out] = bin_fit(x, y, varargin)
% Take a very crowded scatter plot and bin it down to a density map which
% is then fit using some other fitting method. 
% 
% Inputs: x and y values. Does not handle multiple vectors simultaneously! 
%
% Outputs: the fit results struct, and an optional handle to the plot objects. 
%
% Optional arguments: 
%   -func: which fitting function should be used. Give a string naming another
%          function in this package, or a generalized function handle 
%          (there is zero guarantee that other fitters would work with this...). 
%          Default is "polyfit". 
%   -arguments: pass any arguments you'd like, outside the x/y values that 
%               are binned and passed to the fitter. Note that errors are
%               calculated on all y-bins for each x slice. 
%               Use a cell array of keyword-value pairs. Default is {}. 
%   -binning: a scalar or 2-element vector (for x and y bin size). Specify 
%             this in the native units of x and y. 
%             If empty (default) would automatically set the bin width. 
%   -bounds: set the bounds on x and y with a vector: [x_low, x_high, y_low, y_high]. 
%            If empty (default) would use all data points, excluding the top
%            and botton 1 percent values. 
%   -plot: the plotting is not trivial, so use this to produce the scatter
%          with contour lines and fit results on top. This requires that 
%          the fitter outputs a familiar struct that can be used for plotting, 
%          or you can just add that plot yourself. 
%          An optional second output is the handle vector for all these plots. 
%          Default is false. 
%   -contour: draw the contour lines on the plot. Default: false.
%   -legend: add a legend with the fit result printed. Default: false.
%   -font_size: for the legend and axes. Default is 20; 
%   -axes: the usual handle to an axes object. If empty and plot=true it will
%          just produce a new axes using gca(). 
%
%
% 

    input = util.text.InputVars;
    input.input_var('func', [], 'function'); 
    input.input_var('arguments', {}); 
    input.input_var('binning', []); % if not given, use auto binning mode
    input.input_var('bounds', []); % if not given, use the middle core of each distribution (percent to clip on each side is 1/sqrt(number of samples))
    input.input_var('plot', false, 'plotting', 'use_plot'); 
    input.input_var('contour', false); % draw the contour lines
    input.input_var('legend', false); 
    input.input_var('font_size', 20); 
    input.input_var('axes', [], 'axis'); 
    input.scan_vars(varargin{:}); 
    
    if nargin==0, help('util.fit.bin_fit'); return; end
    
    if isempty(input.axes) && input.plot
        input.axes = gca;
    end
        
    %%%%%%%%%%%%%%% GETTING BINNING PARAMETERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isempty(input.bounds)
        
        frac = 1./sqrt(length(x)); 
        
        x_sort = sort(x(~isnan(x))); 
        y_sort = sort(y(~isnan(y)));
        
        x1_idx = floor(length(x_sort)*frac);
        if x1_idx>0
            x1 = x_sort(x1_idx); 
        else
            x1 = x_sort(1); 
        end
        
        x2_idx = ceil(length(x_sort)*(1-frac)); 
        if x2_idx<length(x_sort)
            x2 = x_sort(x2_idx);
        else
            x2 = x_sort(end);
        end
        
        y1_idx = floor(length(y_sort)*frac);
        if y1_idx>0
            y1 = y_sort(y1_idx); 
        else
            y1 = y_sort(1); 
        end
        
        y2_idx = ceil(length(y_sort)*(1-frac)); 
        if y2_idx<length(y_sort)
            y2 = y_sort(y2_idx);
        else
            y2 = y_sort(end);
        end
        
    elseif length(input.bounds)==4
        x1 = input.bounds(1);
        x2 = input.bounds(2);
        y1 = input.bounds(3);
        y2 = input.bounds(4); 
    else
        error('Input "bounds" must be empty or a 4-element vector. Size(bounds)= %s', util.text.print_vec(size(input.bounds), 'x')); 
    end
    
    if isempty(input.binning) % decide the number of bins: sqrt(number of samples), setting the bin width to have that many bins
        
        bin_count = sqrt(length(x)); 
        
        input.binning(1) = (x2-x1)./(bin_count+1);
        input.binning(2) = (y2-y1)./(bin_count+1);
    
    elseif isscalar(input.binning)
        input.binning(2) = input.binning(1);
    elseif length(input.binning)==2
        % pass
    else
        error('Input "binning" must be empty or scalar or a 2-element vector. Size(binning)= %s', util.text.print_vec(size(input.binning), 'x')); 
    end
    
    edges_x = x1:input.binning(1):x2;
    edges_y = y1:input.binning(2):y2;
    
    % central values of each bin
    X = (edges_x(1:end-1)+input.binning(1)/2); 
    Y = (edges_y(1:end-1)+input.binning(2)/2); 
    
    %%%%%%%%%%%%%%%%% BINNING AND PEAK CALCULATION %%%%%%%%%%%%%%%%%%%%%%%%
    
    N = histcounts2(x, y, edges_x, edges_y); % bin count (number)
    N = N'; % turn this matrix so that y axis is vertical and x is horizontal
    
    P = nansum(N.*Y',1)./nansum(N,1); % peak: mean value of slice through y for each x bin
    PE = sqrt(nansum(N.*(Y'-P).^2,1))./nansum(N,1); % peak error: for each slice
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FITTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if isempty(input.func)
        input.func = @util.fit.polyfit;
    elseif ischar(input.func)
        
        if util.text.cs(input.func, 'polyfit')
            input.func = @util.fit.polyfit;
        elseif util.text.cs(input.func, 'power_law')
            input.func = @util.fit.power_law;
        else
            error('Unknown fitting function "%s". Try using "polyfit" or "power law"', input.func); 
        end
        
    elseif isa(input.func, 'function_handle')
        % pass
    else
        error('Must supply the "func" argument with a function handle or name of fitting function. Class(func)= %s', class(input.func)); 
    end
    
    fr = input.func(X,P,'errors',P,input.arguments{:}); 
    
    %%%%%%%%%%%%%%%%%%%%%%%%% PLOTTING %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if input.plot
        
        input.axes.NextPlot = 'replace';
        
        h{1} = plot(input.axes, x, y, '.', 'color', [1 1 1].*0.7); 
        h{1}.DisplayName = 'data'; 
        
        input.axes.NextPlot = 'add';
        
        if input.contour
            contour(input.axes, X, Y, N, 5); 
            h{end+1} = findobj(input.axes, 'type', 'contour');
            h{end}.DisplayName = 'binned'; 
        end
        
        c = [0.9 0.1 0.9];        
        h{end+1} = plot(input.axes, X, P, 'Color', c, 'LineWidth', 3, 'LineStyle', 'none', 'Marker', 's'); 
        h{end}.DisplayName = 'peak values';
        h{end+1} = plot(input.axes, X, P+PE, 'Color', c, 'LineWidth', 2, 'LineStyle', ':'); 
        h{end}.HandleVisibility = 'off';
        h{end+1} = plot(input.axes, X, P-PE, 'Color', c, 'LineWidth', 2, 'LineStyle', ':'); 
        h{end}.HandleVisibility = 'off';
        
        h{end+1} = plot(input.axes, fr.x, fr.ym, 'g-', 'LineWidth', 3); 
        h{end}.DisplayName = fr.model;
        
        input.axes.NextPlot = 'replace';

        if input.legend
            hl = legend(input.axes, 'Location', 'best'); 
            hl.FontSize = input.font_size;
        end
        
        input.axes.FontSize = input.font_size;
        input.axes.XLim = [x1 x2];
        input.axes.YLim = [y1 y2];
        
        if nargout>1 
            h_out = h;
        end
        
    end
    
    
end









