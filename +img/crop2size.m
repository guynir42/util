function [M_out, gap] = crop2size(M_in, size_needed)
% usage: [M_out, gap] =crop2size(M_in, size_needed)
% crops the given array M_in to size size_needed, leaving it in the middle. 
% Won't grow the array. Can handle up to 5D matrices.

    if nargin==0, help('util.img.crop2size'); return; end

    if isempty(size_needed)
        M_out = M_in;
        return;
    end
    
    if ndims(M_in)>6
        error('This function treats up to 6D matrices. If you want more dimensions some coding is needed!'); 
    end
    
    size_needed = util.vec.imsize(size_needed);
    S_in = util.vec.imsize(M_in);
    
    if size_needed(1)<size(M_in,1) || size_needed(2)<size(M_in,2)
        
        gap = (S_in - size_needed)/2;
        gap(1) = max(gap(1),0);
        gap(2) = max(gap(2),0);
        
        y1 = 1+ceil(gap(1));
        y2 = S_in(1)-floor(gap(1));
        x1 = 1+ceil(gap(2));
        x2 = S_in(2)-floor(gap(2));
        
        M_out = M_in(y1:y2,x1:x2,:,:,:,:);
        
        gap = ceil(gap);
        
    else
        M_out = M_in;
        gap = [0 0];
    end
    
end