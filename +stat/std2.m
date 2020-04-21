function S = std2(I)
% calculates the standard deviation of images in the input matrix. 
% output can be 3D or higher. 

import util.stat.var2;
    
    if nargin==0
        help('util.stat.std2');
        return;
    end

    S = sqrt(var2(I));
    
end
