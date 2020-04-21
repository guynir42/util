function h = stretchy_panel(varargin)

    input = util.text.InputVars;
    input.input_var('parent', []);
    input.input_var('position', [0 0 1 1]);
    input.input_var('ratio', 1);
    input.scan_vars(varargin{:});
    
    if isempty(input.parent)
        input.parent = gcf;
    end
    
    h1 = uipanel('Parent', input.parent, 'Position', input.position); % can we just pass the varargin directly?
    h1.SizeChangedFcn = {@callback, input.ratio};
    h1.BorderType = 'none';
    h1.BackgroundColor = [1 1 1];
    h = uipanel('Parent', h1, 'Units', 'Pixels');
    
    callback(h1,[],input.ratio);
    
end

function callback(hndl, ~, ratio)

    pos = getpixelposition(hndl);
    
    width = pos(3);
    height = pos(4);

    if width>height.*ratio
        width = height.*ratio;
    else
        height = width./ratio;
    end
    
    left = (pos(3) - width)/2;
    bottom = (pos(4) - height)/2;
    
    h = findobj('Parent', hndl, 'type', 'uipanel');
    if ~isempty(h)
        h.Position = [left bottom width height];
    end
    
end