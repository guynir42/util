% Usage: image_shifted = shift(image, dx, dy, filler=NaN)
% This function shifts the images (can be 4D matrix) by the number of
% pixels specified by dx and dy, and fills the new pixels with the value
% of "filler" (default NaN). 
% If shifting more than 2D matrix, dx/dy dim1 should match the images dim3
% and dx/dy dim2 should match the images dim4. 
%
% Note: This function rounds fractional pixel shifts. If you need
% fractional shifts, use FourierShift2D in +util/+img.
%
% Currently supports only single, double and uint16. 
% If using integers, filler will default to 0 instead of NaN. 
