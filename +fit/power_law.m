function fr = power_law(x, y, varargin)
% Usage: fr = power_law(x, y, errors, breaks=[], varargin)
% Fit the data in x and y to a (broken) power law with multiple indices. 
% If breaks is empty, just fit a single power law using linear least squares. 
% If breaks is a vector, it is used as the initial guess for fitting the 
% positions of the breaks. The power laws for each section are guessed by 
% using LLS on each section. 
%
% OPTIONAL ARGUMENTS:
%   -sigma: threshold for outlier removal in each iteration of the linear 
%           fit for single power laws. Default is 3. 

    if nargin==0, help('util.fit.power_law'); return; end
    
    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('errors', []); 
    input.input_var('slopes', []); 
    input.input_var('breaks', []); 
    input.input_var('sigma', 3); 
    input.input_var('full', true); 
    input.input_var('plot', false, 'use_plot'); 
    input.input_var('axes', [], 'axis');
    input.input_var('duration', 0.3, 'pause');
    input.scan_vars(varargin{:}); 
  
    if isempty(input.errors)
        input.errors = 1;
    end
    
    if input.plot && isempty(input.axes)
        input.axes = gca;
    end
    
    fr.x = x;
    fr.y = y;
    
    if isempty(input.breaks) % single power law, just use linear least squares on the log of the data
        
        [slope, norm, chi2, dof] = fit_single(x,y,input.errors, input.sigma, input.plot, input.axes, input.duration);
        fr.slopes = slope; 
        fr.norm = norm;
        fr.breaks = [];
        fr.chi2 = chi2;
        fr.dof = dof;
        
        fr.func = util.fit.generate_pl(fr.slopes, fr.breaks, fr.norms(1)); 
        
    elseif isempty(input.slopes) % multiple unknown slopes, must use LLS to find first guesses
         
        func = @(b) comparison_helper(b, x, y, input.errors, input.sigma, input.plot, input.axes, input.duration); 

        opt = optimset('TolFun', 1, 'TolX', 1, 'Display', 'none'); 
        b_new = fminsearch(func, transform_breaks(input.breaks), opt);
        b_new = recover_breaks(b_new);
        
        [~, slopes, norms, chi2s, ndofs] = compare_simple(x, y, input.errors, b_new, input.sigma, input.plot, input.axes, input.duration); 
        fr.slopes = slopes;
        fr.norms = norms;
        fr.breaks = b_new;
        fr.chi2 = nansum(chi2s);
        fr.ndof = nansum(ndofs);
        
        fr.func = util.fit.generate_pl(fr.slopes, fr.breaks, fr.norms(1)); 
        
    else % given both breaks and slopes, jump straight to full minimization
        
        if length(input.slopes)-1~=length(input.breaks)
            error('Slopes vector (length %d) must be one element longer than breaks vector (length %d)!', length(input.power_law), length(input.breaks)); 
        end
        
        % these are just the initial guesses for the full minimization
        fr.slopes = util.vec.tocolumn(input.slopes);
        [x0,idx] = nanmin(abs(x-1)); 
        fr.norms = y(idx).*(x0./x(idx)).^fr.slopes(1); % values closest to x=1 interpolated to x=1
        fr.breaks = util.vec.tocolumn(input.breaks);
        
    end
    
    
    if input.full
        
        func = @(p) comparison_helper_full(p, x, y, input.errors, input.plot, input.axes, input.duration);
%         opt = optimset('TolFun', 1, 'TolX', 1, 'Display', 'none'); 
        
        p_start = double([fr.slopes; transform_breaks(fr.breaks); fr.norms(1); 1]); % initial parameters
        p_new = fminsearch(func, p_start);
        
        N = (length(p_new) - 1)/2; % there needs to be one more slope than breaks, and an additional two parameters (norm_at_1 and sharpness)
        fr.slopes = p_new(1:N);
        fr.breaks = recover_breaks(p_new(N+1:2*N-1));
        fr.norms = p_new(2*N); 
        fr.sharpness = p_new(2*N+1);
        fr.func = util.fit.generate_pl(fr.slopes, fr.breaks, fr.norms, fr.sharpness);
        
        idx = x>0 & y>0;
        X = x(idx);
        Y = y(idx);
        if length(input.errors)==length(x)
            E = input.errors(idx); 
        else
            E = input.errors;
        end

        fr.chi2 = nansum( ( (Y-fr.func(X))./E ).^2);
        fr.ndof = numel(Y)-numel(fr.breaks)-numel(fr.slopes)-2; % norm_at_1 and sharpness are two extra parameters... 
    
    end
    
    fr.model = func2str(fr.func); 
    fr.model = regexprep(fr.model, ' +','');
    fr.model = regexprep(fr.model, '\.\^','^');
    fr.model = regexprep(fr.model, '\.*','*');
    
end

function [slope, norm, chi2, ndof] = fit_single(x, y, errors, sigma, use_plot, ax, duration)
    
    x(x<0) = NaN;
    y(y<0) = NaN;
    
    X = log10(x); 
    Y = log10(y); 
    E = abs(log10(y+errors)-log10(y-errors))/2;
    
    fr = util.fit.polyfit(X, Y, 'order', 1, 'sigma', sigma, 'variances', E.^2,...
        'plot', use_plot, 'ax', ax, 'pause', duration); 
    
    norm = 10.^fr.coeffs(1,:); 
    slope = fr.coeffs(2,:); 
    chi2 = fr.chi2;
    ndof = fr.ndof;
    
end

function b_trans = transform_breaks(breaks)
    
    b_trans = log10(breaks./breaks(1)); 
    b_trans(1) = breaks(1); 
    
end

function b = recover_breaks(b_trans)
    
    b = b_trans(1).*10.^b_trans;
    b(1) = b_trans(1); 
    
end

function chi2 = comparison_helper(b, x, y, e, sigma, use_plot, ax, duration) % translate the b vector to break points
    
    if any(b<=0)
        chi2 = Inf;
    else
        chi2 = compare_simple(x, y, e, recover_breaks(b), sigma, use_plot, ax, duration); 
    end
    
%     fprintf('b= %16.14f | Chi2/ndof= %16.14f\n', b(1), chi2); 
    
end

function [chi2_reduced, slopes, norms, chi2s, ndofs] = compare_simple(x, y, errors, breaks, sigma, use_plot, ax, duration)
    
    lower_bound = nanmin(x); 
    
    chi2_total = 0;
    ndof_total = 0;
    
    if use_plot
        prev_state = ax.NextPlot;
    end
    
    slopes = [];
    norms = [];
    chi2s = [];
    ndofs = [];
    
    for ii = 1:length(breaks)+1
        
        if ii==length(breaks)+1
            idx = x>=breaks(end);
        else
            idx = x>=lower_bound & x<breaks(ii);
            lower_bound = breaks(ii); 
        end
        
        X = x(idx);
        Y = y(idx);
        if isscalar(errors)
            E = errors;
        else
            E = errors(idx); 
        end
        
        if ~isempty(X)
            [slope, norm, chi2, ndof] = fit_single(X, Y, E, sigma, 0, 0, 0); 
        else
            slope = NaN;
            norm = NaN;
            chi2 = 0;
            ndof = 0; 
        end
        
        chi2_total = chi2_total + chi2;
        ndof_total = ndof_total + ndof;
        
        slopes = [slopes; slope];
        norms = [norms; norm];
        chi2s = [chi2s; chi2];
        ndofs = [ndofs; ndof];
        
        if use_plot
            
            if ii>1
                ax.NextPlot = 'add';
            end
            
            loglog(ax, abs(x), abs(y), 'k.', abs(X), abs(Y), 'o', abs(X), abs(norm.*X.^slope), '-r'); 
            
        end
        
    end
    
    if use_plot
        pause(duration); 
        ax.NextPlot = prev_state;
    end

    chi2_reduced = chi2_total./ndof_total;
    
end

function chi2 = comparison_helper_full(b, x, y, e, use_plot, ax, duration) % the b in this case includes the breaks, the slopes, the norm_at_1 and the sharpness parameters! 
    
    import util.text.print_vec;
    
    if length(b)<5
        error('Input to comparison_helper_full must include at least two slopes, one break, norm_at_1 and sharpness parameters!');
    end
    
    N = (length(b) - 1)/2; % there needs to be one more slope than breaks, and an additional two parameters (norm_at_1 and sharpness)
    
    slopes = b(1:N); 
    breaks_trans = (b(N+1:2*N-1));
    breaks = recover_breaks(breaks_trans);
    norm_at_1 = b(2*N); 
    sharpness = b(2*N+1); 
    
    
    if any(breaks_trans<=0) || norm_at_1<0 || sharpness<0
        chi2 = Inf;
    else
        chi2 = compare_full(x, y, e, slopes, breaks, norm_at_1, sharpness, use_plot, ax, duration); 
    end
    
%     fprintf('slopes= %s | breaks= %s | norm= %6.4f | sharpness= %6.4f | Chi2= %16.14f\n', print_vec(slopes), print_vec(breaks), norm_at_1, sharpness, chi2); 

end

function [chi2, slopes, norm_at_1] = compare_full(x, y, errors, slopes, breaks, norm_at_1, sharpness, use_plot, ax, duration)
    
    func = util.fit.generate_pl(slopes, breaks, norm_at_1, sharpness);
    
    idx = x>0 & y>0;
    X = x(idx);
    Y = y(idx);
    
    if length(errors)==length(x)
        E = errors(idx); 
    else
        E = errors;
    end
    
    chi2 = nansum( ( (Y-func(X))./E ).^2);
    
%     chi2 = nansum( ( (log10(Y)-log10(func(X)))./log10(E+1) ).^2);


%     ndof = numel(Y)-numel(breaks)-numel(slopes)-2; % norm_at_1 and sharpness are two extra parameters... 
    
%     chi2_reduced = chi2./ndof;
    
    if use_plot
        
        loglog(ax, X, Y, '.', sort(X), func(sort(X)), '-r'); 
        
        pause(duration);
        
    end
    
end






