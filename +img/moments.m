function [m1x, m1y, m2x, m2y, mxy] = moments(I, varargin)
% Usage: [m1x, m1y, m2x, m2y, mxy] = moments(I, varargin)
% Calculate the 1st and 2nd moments of image I (or 3 or 4 dimentional matrix)
% If sum of input image I is zero: 1st moments set to 0, 2nd moments to NaN.
% Negative 2nd moments also set to NaN.
%
% OPTIONAL ARGUMENTS: may be added later...
%
%
% OUTPUTS:
% m1x and m1y: first moments
% m2x, m2y and mxy: second moments, x^2, y^2, and x*y


    import util.stat.sum2;

    if nargin==0, help('util.img.moments'); return; end
    
    S = sum2(I);

    c = size(I);
    c = c(1:2);
    
    [X,Y] = meshgrid((1:c(2))-floor(c(2)/2)-1, (1:c(1))-floor(c(1)/2)-1); 

    m1x = sum2(I.*X)./S;
    m1y = sum2(I.*Y)./S;
    
    % should we ever reach such values??
    m1x(abs(m1x)>c(2)) = NaN;
    m1y(abs(m1y)>c(1)) = NaN;
    
    if nargout>2

        m2x = sum2(I.*(X-m1x).^2)./S;
        m2y = sum2(I.*(Y-m1y).^2)./S;
        mxy = sum2(I.*(X-m1x).*(Y-m1y))./S;

        % make sure there are no S==0 elements
        m1x(S==0) = 0;
        m1y(S==0) = 0;
        m2x(S==0) = NaN;
        m2y(S==0) = NaN;
        mxy(S==0) = NaN;

        % make sure there are no negative second moments
        m2x(m2x<0) = NaN;
        m2y(m2y<0) = NaN;

    end

end