function A = imshift(im, shiftRows, shiftCols)
% usage: imshift(im, shiftRows, shiftCols)
% moves the image around by the required number of rows/cols. 

if nargin==0, help('util.img.imshift'); return; end

shiftRows = round(shiftRows);
shiftCols = round(shiftCols);

A = zeros(size(im), 'like', im);

if shiftRows >= 0 && shiftCols >= 0
    A(1+shiftRows:end,1+shiftCols:end) = im(1:end-shiftRows,1:end-shiftCols);
elseif shiftRows >= 0 && shiftCols < 0
    A(1+shiftRows:end,1:end+shiftCols) = im(1:end-shiftRows,1-shiftCols:end);
elseif shiftRows < 0 && shiftCols >= 0
    A(1:end+shiftRows,1+shiftCols:end) = im(1-shiftRows:end,1:end-shiftCols);
else
    A(1:end+shiftRows,1:end+shiftCols) = im(1-shiftRows:end,1-shiftCols:end);
end

% stolen shamelessly from https://www.mathworks.com/matlabcentral/fileexchange/37395-trainable-cosfire-filters-for-keypoint-detection-and-pattern-recognition?focused=3866015&tab=function
