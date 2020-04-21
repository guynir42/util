function M = median2(I)
% Calculates the median of each image in the input matrix. 
% Accepts 2D, 3D and 4D matrices. 
% Outputs a 3D or 4D result. 

    if nargin==0
        help('util.stat.median2');
        return;
    end

    M = zeros(1,1,size(I,3), size(I,4), 'like', I);

    for ii = 1:size(I,3)
        for jj = 1:size(I,4)
            single_image = I(:,:,ii,jj);
            M(1,1,ii,jj) = nanmedian(single_image(:));
        end
    end

end