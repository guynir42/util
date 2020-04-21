function [pix, masked_image] = annulusPixels(I, r1, r2, quadrants, num_edges)
% usage: [pix, masked_image] = annulusPixels(I, r1, r2, quadrants, num_edges)
% Returns all pixels of image I that are between r1 and r2. 
% Use "quadrants" to look at quarters of the image (either a vector of
% numbers from 1 to 4 or a 4-element vector of 0s and 1s). Default is all. 
% Use "num_edges": include no edges (0), include leading edge (1, default),
% or include both edges (2). 
%
% Outputs are a vector of pixel values from the selection, and an optional
% second output is the image where only the selected pixels are not masked.

    if nargin==0, help('util.img.annulusPixels'); return; end

    if nargin<2 || isempty(r1)
        r1 = 0;
    end

    if nargin<3 || isempty(r2)
        r2 = Inf;
    end

    if nargin<4
        quadrants = [];
    end
    
    if nargin<5 || isempty(num_edges)
        num_edges = 1;
    end
    
    x_c = (size(I,2)/2) + 0.5;
    y_c = (size(I,1)/2) + 0.5;
    
    x = (1:size(I,2)); % center position of each bin, for each pixel...
    x = repmat(x, size(I,1),1); % for all pixels.
    x = x - x_c; % relative to the center of the image...
    
    y = (1:size(I,1))'; % center position of each bin for each pixel...
    y = repmat(y, 1, size(I,2));
    y = y - y_c;
    
    % mask off distances...
    dist = sqrt(x.^2+y.^2); % the distances from center for each bin
    rmask = logical(logical(dist>=r1) .* logical(dist<=r2));

    if ~isempty(quadrants)
        
        if isscalar(quadrants) && isnumeric(quadrants) && quadrants>0 && quadrants<=4
            v = zeros(1,4);
            v(quadrants) = 1;
            quadrants = v;
        end
        
        % mask off quadrants
        qmask = false(size(I));
        
        lead_edge = num_edges>=1;
        trail_edge = num_edges>=2;
        
        if isvector(quadrants) && length(quadrants)==4
            if quadrants(1), qmask(1:ceil(y_c-1+lead_edge), ceil(x_c+1-trail_edge):end) = 1; end
            if quadrants(2), qmask(1:ceil(y_c-1+trail_edge), 1:ceil(x_c-1+lead_edge)) = 1; end
            if quadrants(3), qmask(ceil(y_c+1-lead_edge):end, 1:ceil(x_c-1+trail_edge)) = 1; end
            if quadrants(4), qmask(ceil(y_c+1-trail_edge):end, ceil(x_c+1-lead_edge):end) = 1; end
        end
        
    else
        qmask = true(size(I));
    end
    
    mask = logical(qmask.*rmask);
    
    pix = I(mask);

%     disp(['size(I)= ' num2str(size(I)) ' | size(mask)= ' num2str(size(mask))]);
    
    masked_image = bsxfun(@times, I, mask);
    
end