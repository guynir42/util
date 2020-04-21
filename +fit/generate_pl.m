function fun = generate_pl(varargin)
% Usage: fun = generate_pl(power_law, breaks=[], norm=1, ref=1, sharpness=1)
% Generate function for a (broken) power law with one or more indices. 
% Strings together the different power laws smoothly, by combining them 
% according to the following rule (q1 and q2 are the indices):
% if q1<q2: simply add together the two power laws. 
% if q1>q2: take the inverse of the addition of the inverses of the two. 
% In both cases, the first power law is dominant for small x, and the second
% for large x. 
% After the first two power laws are constructed, the next power law section
% is added using the same addition rule, using q2 as the new q1 and q3 as 
% the new q2 and so on. 
% 
% OPTIONAL ARGUMENTS (can be given in order or as keywords):
%   -power_law: must be a vector or scalar. 
%   -breaks: x positions of the breaking points between power law sections. 
%            vector of length equal to length of power_law minus one. 
%   -norm: The overall normalization of the power law at some x0. Default 1. 
%   -reference: give the x0 where the normalization is defined. Default 1. 
%   -sharpness: the transitions can be made more or less sharp by changing
%               this parameter. E.g., sharpness=0.5 uses addition in quadrature
%               instead of simple addition. Default 1. 

    if nargin==0, help('util.fit.generate_pl'); return; end
    
    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('slopes', -1, 'slopes_vector', 'power_law', 'pl_vector', 'power_law_vector'); % list of power laws 
    input.input_var('breaks', [], 'break_positions', 'break_vector', 'breaks_vector'); % list of break positions, must be sorted! 
    input.input_var('norm', 1, 'normalization'); % value of function at some reference x
    input.input_var('reference', 1); % what to use as reference x
    input.input_var('sharpness', 1); % sharpness of the transition (choose 0.5 for soft, quadrature-addition-like transitions)
    input.scan_vars(varargin{:}); 
    
    if isempty(input.slopes)
        error('Must give a non-empty vector of power laws!');
    end
    
    if length(input.slopes)-1~=length(input.breaks)
        error('Slopes vector (length %d) must be one element longer than breaks vector (length %d)!', length(input.slopes), length(input.breaks)); 
    end
    
    if ~isequal(input.breaks, sort(input.breaks))
        error('Must give a sorted vector of numbers as "breaks" parameter! breaks= %s', util.text.print_vec(input.breaks)); 
    end
    
    str = sprintf('x.^(%20.20f)', input.slopes(1)); 
    
    prev_break_par = 1;
    
    for ii = 2:length(input.slopes)
        
        this_break_par = input.breaks(ii-1).^((input.slopes(ii)-input.slopes(ii-1))./input.slopes(ii)).*prev_break_par.^(input.slopes(ii-1)./input.slopes(ii));

        if input.slopes(ii)==0 || this_break_par==0 || isinf(this_break_par) || isnan(this_break_par)
            this_break_par = (input.breaks(ii-1)./prev_break_par).^input.slopes(ii-1);
            new_str = sprintf('%20.20f', this_break_par); 
        else
            new_str = sprintf('(x./%20.20f).^(%20.20f)', this_break_par, input.slopes(ii)); 
        end
        
        prev_break_par = this_break_par;
        
        invert = input.slopes(ii-1) > input.slopes(ii); % if true, must add the power law in the inverted way: 1/(1/x^q1 + 1/x^q2)
        
        if invert
            str = sprintf('(1./%s.^(%20.20f) + 1./%s.^(%20.20f)).^(-1./%20.20f)', str, input.sharpness, new_str, input.sharpness, input.sharpness);
        else
            str = sprintf('(%s.^(%20.20f) + %s.^(%20.20f)).^(1./%20.20f)', str, input.sharpness, new_str, input.sharpness, input.sharpness);
        end
        
    end
    
    fun = str2func(sprintf('@(x) %20.20f/%20.20f.^(%20.20f) .* %s', input.norm, input.reference, input.slopes(1), str)); 
    
end