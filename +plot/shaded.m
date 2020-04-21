function [line_handle, fill_handle] = shaded(x,y,err,varargin)

    input = util.text.InputVars;
    input.input_var('axes', [], 'axis', 'parent');
    input.input_var('LineColor', [0 0 0], 'Color');
    input.input_var('LineStyle', '-');
    input.input_var('LineWidth', 2);
    input.input_var('FillColor', 0.8.*[1 1 1]);
    input.input_var('positive', 0);
    input.scan_vars(varargin{:});
    
    if isempty(input.axes)
        input.axes = gca;
    end
    
    x = util.vec.torow(x);
    y = util.vec.torow(y);
    
    if size(x,2)~=size(y,2)
        error(['Size mismatch between x (' num2str(size(x)) ') and y (' num2str(size(y)) ')']);
    end
    
    if size(err,1)==size(x,2) && (size(err,2)==1 || size(err,2)==2)
        err = err';
    elseif size(err,2)==size(x,2) && (size(err,1)==1 || size(err,1)==2)
        % pass
    else 
        error(['Size mismatch between x (' num2str(size(x)) ') and err (' num2str(size(err)) ')']);
    end
    
    if size(err,1)==1 
        err = repmat(err, [2,1]);
    end
    
    outline_x = [x flip(x)];
    outline_y = [y-err(1,:) flip(y+err(2,:))];
    
    if input.positive
        outline_temp = outline_y;
        outline_temp(outline_y<=0) = [];
        m = min(outline_temp);
        outline_y(outline_y<=0) = m;
    end
    
    holding_pattern = input.axes.NextPlot;
    
    fill_handle = fill(outline_x, outline_y, input.FillColor, 'Parent', input.axes, 'EdgeColor', 'none');
    
    input.axes.NextPlot = 'add';
    
    if input.LineWidth>0
        line_handle = plot(input.axes, x, y, 'Color', input.LineColor, 'LineWidth', input.LineWidth, 'LineStyle', input.LineStyle);
    end
    
    input.axes.NextPlot = holding_pattern;
    
end

% reference: https://www.mathworks.com/matlabcentral/answers/180829-shade-area-between-graphs

