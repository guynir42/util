function setImage(I, ax)
   
    if ndims(I)>3
        I = I(:,:,end,end);
    elseif ndims(I)>2
        I = I(:,:,end);
    end
    
    if nargin<2 || isempty(ax)
        ax = gca;
    end
    
    if ~isvalid(ax)
        ax = axes('Parent', ax.Parent); 
        axis(ax, 'image');
    end
    
    im_handle = findobj(ax, 'Type', 'Image');
    if isempty(im_handle) || numel(im_handle)>1
        imagesc(ax, I);
%         ax.PlotBoxAspectRatio = [1 1 1];
        axis(ax, 'image');
        colorbar(ax);
    else
        im_handle.CData = I;
    end
    
end