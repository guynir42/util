function M_out = fit2size(M_in, size_needed)
% usage: fit2size(M_in, size_needed)
% Pads or crops the given array M_in to size M_size, putting it in the middle. 
% Calls pad2size then crop2size. 

    import util.img.*;

    if nargin==0, help('util.img.fit2size'); return; end
    
    M_out = crop2size(pad2size(M_in, size_needed), size_needed);
    
end