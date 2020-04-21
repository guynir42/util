function result = stat_eval(func, values, dim)
% Usage: result = stat_eval(func, values, dim)
% Provides a uniform interface to common statistical functions like: 
% mean, median, max, min, std, var. 
% Input "func" is the function name (string) or function handle. 
% Input "values" are the numbers you want the statistics on. 
% Input "dim" is what dimension to run the function on. 
% (newer versions of matlab accept dim="all" and dim as vector)
%
% Will always use the NaN safe version of these functions. 
%
% 

    import util.text.cs;

    if nargin==0, help('util.stat.feval'); return; end

    if ~ischar(func) && ~isa(func, 'function_handle')
        error('Input "func" must be a function handle or string. Got class(func)= "%s". ', class(func)); 
    end
    
    if nargin<3 || isempty(dim)
        error('Must supply a dimension to run the statistics on!');
    end
    
    if cs(func, 'mean', 'nanmean') || isequal(func, @mean) || isequal(func, @nanmean)
        result = nanmean(values, dim); 
    elseif cs(func, 'median', 'nanmedian') || isequal(func, @median) || isequal(func, @nanmedian)
        result = nanmedian(values, dim);
    elseif cs(func, 'max', 'nanmax') || isequal(func, @max) || isequal(func, @nanmax)
        result = nanmax(values, [], dim); 
    elseif cs(func, 'min', 'nanmin') || isequal(func, @min) || isequal(func, @nanmin)
        result = nanmin(values, [], dim);
    elseif cs(func, 'std', 'nanstd') || isequal(func, @std) || isequal(func, @nanstd)
        result = nanstd(values, [], dim);
    elseif cs(func, 'var', 'nanvar') || isequal(func, @var) || isequal(func, @nanvar)
        result = nanvar(values, [], dim);
    else
        error('Unknown function handle "%s". Use mean, median, max, min, std, or var. ', char(func)); 
    end
        
    
end