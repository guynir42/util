function M = annulusMask(ImSize, varargin)
% Creates an image with a logical mask the shape of an annulus. 
% Usage: annulusMask(ImSize, varargin)
% Input ImSize can be one- or two- element vector. 
%
% OPTIONAL ARGUMENTS
%       -R_min: internal radius of annulus (default is 0).
%       -R_max: external radius (default is half ImSize minus 1). 
%       -feather: number of pixels to feather the annulus edges default: []
%                 means no feathering. 

    import util.text.cs;
    import util.img.gaussian2;
    import util.stat.sum2;

    if nargin==0
        help('util.img.annulusMask');
        return;
    end
    
    R_min = 0;
    R_max = floor(min(ImSize)/2)-1; 
    feather = [];
    oversampling = [];
    
    for ii = 1:2:length(varargin)
        
        if cs(varargin{ii}, {'minimum_radius', 'r_min'}, 3)
            R_min = varargin{ii+1};
        elseif cs(varargin{ii}, {'maximum_radius', 'r_max'}, 3)
            R_max = varargin{ii+1};
        elseif cs(varargin{ii}, 'feather')
            feather = varargin{ii+1};
        elseif cs(varargin{ii}, 'oversampling', 'sampling')
            oversampling = varargin{ii+1};
        end
        
    end
    
    if ~isempty(oversampling) && round(oversampling)~=oversampling
        error('must use a round value for "oversampling"!');
    end
    
    ImSize = round(ImSize);
    
    if isscalar(ImSize)
        ImSize = [ImSize ImSize];
    end
    
    if feather
        k = gaussian2(feather,[],[],feather*2+1);
        k = k./(sum2(k));
        ImSize = ImSize+size(k)-1;
    end
        
    ImSize = ImSize(1:2);
    
    if ~isempty(oversampling) && oversampling>1
        ImSize = ImSize*oversampling;
        R_max = R_max*oversampling;
        R_min = R_min*oversampling;
    end
    
    [x,y] = meshgrid(1:ImSize(2), 1:ImSize(1));

    center = (ImSize/2)+0.5;
    
    x = x - center(2);
    y = y - center(1);
    
    dist = sqrt(x.^2+y.^2);
    
    method = 1;
    
    if method==1
    
        M = ones(round(ImSize));
        M(dist<R_min) = 0;
        M(dist>R_max) = 0;
        
    elseif method==2
    
        M = R_max-dist;
        M(M>1) = 1;
        M(M<0) = 0;

        if R_min>0
            M2 = dist-R_min;
            M2(M2>1) = 1;
            M2(M2<0) = 0;
            M = M & M2;
        end
        
    end
    
    if ~isempty(oversampling) && oversampling>1
        M = util.img.downsample(M, oversampling, 'mean');
    end
        
    if feather
        M = filter2(k, M, 'valid');
    end

end