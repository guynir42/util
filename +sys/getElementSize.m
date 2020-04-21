function bytes = getElementSize(x, units)
% Usage: bytes = getElementSize(x, units)
% Return the number of bytes taken by each element in the array. 
% Examples: a regular double matrix is 8 bytes, single is 4, etc. 

    import util.text.cs;
    
    if nargin==0, help('util.sys.getElementSize'); return; end

    w = whos('x');
    bytes = w.bytes / numel(x);
    
    if nargin<2 || isempty(units)
        units = 'bytes';
    end
    
    if cs(units, 'bytes')
        % do nothing
    elseif cs(units, 'KBs', 'kilobytes')
        bytes = bytes/1024;
    elseif cs(units, 'MBs', 'megabytes')
        bytes = bytes/1024^2;
    elseif cs(units, 'GBs', 'gigabytes')
        bytes = bytes/1024^3;
    else
        error('Unknown unit type: "%s". Use "bytes" or "KBs" or "MBs" or "GBs"'); 
    end

    
end

% see https://www.mathworks.com/matlabcentral/answers/139977-determine-number-of-bytes-per-element-under-program-control