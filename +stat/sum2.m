function S = sum2(I, outtype, nan_flag)
% usage: sum2(I, outtype='double')
% calculates the sum of images in the input matrix. 
% returns a 3D or 4D (or higher) output. 
% will output double by default. Use outtype to require a different type. 

    if nargin==0
        help('util.stat.sum2');
        return;
    end

    if nargin<2 || isempty(outtype)
        if isa(I, 'single')
            outtype = 'native';
        else
            outtype = 'double';
        end
    end
    
    if nargin<3 || isempty(nan_flag)
        nan_flag = 'omitnan';
    end
    
    S = sum(sum(I,1, outtype, nan_flag),2, outtype, nan_flag);

end