classdef GraphicButton < handle
% Usage: GraphicButton(parent, position, owner, var_name, type, str1, str2, font_size, self_name, buttons_name, color_on, color_off, tooltip)
% Wrapper for uicontrol. 
% Has some defaults for controlling an object "owner" that is responsible
% for this GUI object. Also adds itself to the GUI's button array, for easy
% updating. 
% Options for "type": toggle, push, info, input, input_text, custom. 
%

    properties
        
        owner; % this object owns the gui that owns this button
        variable = ''; % the name of the variable that is connected to this button
        type = 'push'; % push (default), toggle, input, info, picker, custom
        
        % the two parts come before and after the value
        str1 = '';
        str2 = '';
        
        font_size = ''; % default is regular (large) font. Otherwise use 'edit' or 'small'. actual size is define by owner.(obj.self_name)
        
        color_on = [0 0.3 1]; % apply this color when on
        color_off;
        
        margin;
        
        func = @owner.update; % callback for this object
        
        self_name; % containing object should have a "gui" object (or something else)
                
        control@matlab.ui.control.UIControl;
        
    end
    
    properties(Dependent=true)
        
        Parent;
        Position;
        String;
        Value;
        Callback;
        FontSize;
        Enable;
        BackgroundColor;
        ForegroundColor;
        Tooltip;
        
    end
    
    properties(Hidden=true)
        
        default_color = [0.94 0.94 0.94];
        version = 1.00; 
        
    end
    
    methods % constructor
        
        function obj = GraphicButton(parent, position, owner, var_name, type, str1, str2, font_size, self_name, buttons_name, color_on, color_off, tooltip, margin)

            import util.text.cs;
            
            if nargin<4
                error('need 4 inputs! Usage: GraphicButton(parent, position, owner, var_name, [type], [str1], [str2], [font_size])');
            end
            
            if nargin<5 || isempty(type)
                type = 'push';
            end
            
            if nargin<6 || isempty(str1)
                str1 = '';
            end
            
            if nargin<7 || isempty(str2)
                str2 = '';
            end
            
            if nargin<8 || isempty(font_size)
                obj.font_size = '';
            else
                obj.font_size = font_size;
            end
            
            if nargin<9 || isempty(self_name)
                self_name = 'gui';
            end
            
            if nargin<10 || isempty(buttons_name)
                buttons_name = 'buttons';
            end
            
            if nargin<11 || isempty(color_on)
                color_on = [];
            end
            
            if nargin<12 || isempty(color_off)
                color_off = [];
            end
            
            if nargin<13 || isempty(tooltip)
                tooltip = '';
            end
            
            if nargin<14 || isempty(margin)
                obj.margin = [];
            else
                obj.margin = margin;
            end
            
            if cs(type, 'push')
                
                if isempty(str1)
                    str1 = var_name;
                end
                
                obj.control = uicontrol(parent, 'Style', 'pushbutton', 'Units', 'Normalized', 'Position', position);
                obj.Callback = @obj.callback_push;
                
            elseif cs(type, 'toggle')
                
                if isempty(str1) && isempty(str2)
                    str1 = ['no ' var_name];
                    str2 = ['use ' var_name];
                end
                
                obj.control = uicontrol(parent, 'Style', 'pushbutton', 'Units', 'Normalized', 'Position', position);
                obj.Callback = @obj.callback_toggle;
                
            elseif cs(type, 'auto')
                if isempty(str1) 
                    str1 = var_name;
                end
                
                if isempty(str2)
                    str2 = ''; % not in use right now
                end
                
                obj.control = uicontrol(parent, 'Style', 'pushbutton', 'Units', 'Normalized', 'Position', position);
                obj.Callback = @obj.callback_auto;
                
            elseif cs(type, 'input', 'input text', 'input custom')
                
                if isempty(str1)
                    str1 = [var_name '= '];
                end
                
                obj.control = uicontrol(parent, 'Style', 'edit', 'Units', 'Normalized', 'Position', position);
                
                if cs(type, 'input text', 'input custom', 7)
                    obj.Callback = @obj.callback_input_text;
                else
                    obj.Callback = @obj.callback_input;
                end
                
            elseif cs(type, 'info')
                
                obj.control = uicontrol(parent, 'Style', 'pushbutton', 'Units', 'Normalized', 'Position', position);
                obj.Callback = @obj.callback_info;
                
            elseif cs(type, 'picker')
                
                obj.control = uicontrol(parent, 'Style', 'popupmenu', 'Units', 'Normalized', 'Position', position);
                obj.String = str1;
                
            elseif cs(type, 'custom')
                
                obj.control = uicontrol(parent, 'Style', 'pushbutton', 'Units', 'Normalized', 'Position', position);
                
                obj.String = str1;
                
            end
              
            obj.owner = owner;
            obj.variable = var_name;
            obj.type = type;
            obj.str1 = str1;
            obj.str2 = str2;
            obj.self_name = self_name;
            obj.color_on = color_on;
            obj.color_off = color_off;
            obj.Tooltip = tooltip;
            obj.update;
            
            if isprop(obj.owner.(self_name), buttons_name)
                
                obj.owner.(self_name).(buttons_name){end+1} = obj;
                
            end
            
            if ~isempty(obj.margin)
                
                margin_vec = obj.margin;
                
                if isscalar(margin_vec)
                    margin_vec = [1 1].*margin_vec;
                end
                
                obj.control.Position = obj.control.Position + [margin_vec -margin_vec.*2];
                
            end
            
        end
        
    end
    
    methods % getters
        
        function val = get.Parent(obj)
            
            val = obj.control.Parent;
            
        end
        
        function val = get.Position(obj)
            
            val = obj.control.Position;
            
        end
        
        function val = get.String(obj)
            
            val = obj.control.String;
            
        end
        
        function val = get.Value(obj)
            
            val = obj.control.Value;
            
        end
        
        function val = get.Callback(obj)
            
            val = obj.control.Callback;
            
        end
        
        function val = get.FontSize(obj)
            
            val = obj.control.FontSize;
            
        end   
        
        function val = get.Enable(obj)
            
            val = obj.control.Enable;
            
        end
        
        function val = get.BackgroundColor(obj)
            
            val = obj.control.BackgroundColor;
            
        end
        
        function val = get.ForegroundColor(obj)
            
            val = obj.control.ForegroundColor;
            
        end
        
        function val = get.Tooltip(obj)
            
            val = obj.control.TooltipString;
            
        end
        
    end
    
    methods % setters
        
        function set.Parent(obj, val)
            
            obj.control.Parent = val;
            
        end
        
        function set.Position(obj, val)
            
            obj.control.Position = val;
            
        end
        
        function set.String(obj, val)
            
            obj.control.String = val;
            
        end
        
        function set.Value(obj, val)
            
            obj.control.Value = val;
            
        end
        
        function set.Callback(obj, val)
            
            obj.control.Callback = val;
            
        end
        
        function set.FontSize(obj, val)
            
            obj.control.FontSize = val;
            
        end
                
        function set.Enable(obj, val)
            
            obj.control.Enable= val;
            
        end
        
        function set.BackgroundColor(obj, val)
            
            obj.control.BackgroundColor= val;
            
        end
        
        function set.ForegroundColor(obj, val)
            
            obj.control.ForegroundColor= val;
            
        end
        
        function set.Tooltip(obj, val)
            
            obj.control.TooltipString = val;
            
        end
        
    end
    
    methods % update
        
        function val = getVariable(obj)
           
            if isempty(obj.variable)
                val = [];
            else
                
                vars = split(obj.variable, '.');

                for ii = 1:length(vars)
                    S(ii) = struct('type', '.', 'subs', vars{ii});
                end

                if isempty(obj) || isempty(obj.owner)
                    val = [];
                elseif length(S)>1 && isempty(subsref(obj.owner, S(1)))
                    val = [];
                else
                    val = subsref(obj.owner, S);
                end
                
            end
            
        end
        
        function update(obj)
            
            import util.text.cs;
            
            font_size = obj.font_size;            
            if ~isempty(font_size) && font_size(end)~='_'
                font_size = [font_size '_'];
            end
            
            if cs(obj.type, 'push')
                
                obj.String = [obj.str1 obj.str2];
                obj.FontSize = obj.owner.(obj.self_name).([font_size 'font_size']);
                
            elseif cs(obj.type, 'toggle')
                
                val = obj.getVariable;
            
                if val
                    obj.String = obj.str2;
                    if ~isempty(obj.color_on)
                        obj.control.ForegroundColor = obj.color_on;
                    elseif ~isempty(obj.color_off) % if the off color is not set to default, must turn back to default when "on"
                        obj.control.ForegroundColor = 'black';
                    end
                else
                    obj.String = obj.str1;
                    if ~isempty(obj.color_off)
                        obj.control.ForegroundColor = obj.color_off;
                    elseif ~isempty(obj.color_on)
                        obj.control.ForegroundColor = 'black'; % if the in color is not set to default, must turn back to default when "off"
                    end
                end
                
                obj.FontSize = obj.owner.(obj.self_name).([font_size 'font_size']);
                
            elseif cs(obj.type, 'auto')
                
                val = obj.getVariable;
            
                if isempty(val)
                    obj.String = [obj.str1 ' auto'];
                    obj.control.ForegroundColor = 0.4*[1 1 1];
                elseif val
                    obj.String = [obj.str1 ' on'];
                    if ~isempty(obj.color_on)
                        obj.control.ForegroundColor = obj.color_on;
                    else
                        obj.control.ForegroundColor = 'black';
                    end
                elseif ~val
                    obj.String = [obj.str1 ' off'];
                    if ~isempty(obj.color_off)
                        obj.control.ForegroundColor = obj.color_off;
                    else
                        obj.control.ForegroundColor = 'black';
                    end
                end
                
                obj.FontSize = obj.owner.(obj.self_name).([font_size 'font_size']);
                
            elseif cs(obj.type, 'input', 'input text')
                
                val = obj.getVariable;
            
                if cs(obj.type, 'input text', 7)
                    obj.String = [obj.str1 val obj.str2];
                else
                    obj.String = [obj.str1 util.text.print_vec(val) obj.str2];
                end
                
                if isempty(obj.font_size)
                    obj.FontSize = obj.owner.(obj.self_name).edit_font_size;
                else
                    obj.FontSize = obj.owner.(obj.self_name).([font_size 'font_size']);
                end
                
            elseif cs(obj.type, 'info')
                
                val = obj.getVariable;
            
                obj.FontSize = obj.owner.(obj.self_name).([font_size 'font_size']);
                if isempty(val)
                    obj.String = [obj.str1 ' ' obj.str2];
                elseif ischar(val) || isstring(val)
                    obj.String = [obj.str1 ' ' val ' ' obj.str2];
                else
                    obj.String = [obj.str1 num2str(val) obj.str2];
                end
                
            elseif cs(obj.type, 'custom', 'input custom')
                
                obj.FontSize = obj.owner.(obj.self_name).([font_size 'font_size']);
            
            else
                obj.FontSize = obj.owner.(obj.self_name).([font_size 'font_size']);
            end
            
        end
        
    end
    
    methods % callback
        
        function setVariable(obj, val)
            
            if isempty(obj.variable)
                return;
            else
                
                vars = split(obj.variable, '.');

                for ii = 1:length(vars)
                    S(ii) = struct('type', '.', 'subs', vars{ii});
                end

                obj.owner = subsasgn(obj.owner, S, val);
            
            end
            
        end
        
        function callback_push(obj, ~, ~)
            
            if obj.owner.(obj.self_name).debug_bit, disp(['callback: ' obj.variable]); end
            
            if isempty(obj.variable)
                % pass
            else

                if isprop(obj.owner.(obj.self_name), 'latest_error')
                    obj.owner.(obj.self_name).latest_error = '';
                end
                
                if isprop(obj.owner.(obj.self_name), 'latest_warning')
                    obj.owner.(obj.self_name).latest_warning = '';
                    lastwarn('');
                end

                try

                    if isempty(obj.str2)
                        
                        c = strsplit(obj.variable, '.'); 
                        
                        if length(c)==1
                            if ismethod(obj.owner, c{1})
                                obj.owner.(c{1});
                            elseif isprop(obj.owner, c{1}) && ismethod(obj.owner.(c{1}), 'makeGUI')
                                obj.owner.(c{1}).makeGUI;
                            end
                        elseif length(c)==2
                            if ismethod(obj.owner.(c{1}), c{2})
                                obj.owner.(c{1}).(c{2});
                            elseif isprop(obj.owner.(c{1}), c{2}) && ismethod(obj.owner.(c{1}).(c{2}), 'makeGUI')
                                obj.owner.(c{1}).(c{2}).makeGUI;
                            end
                        end
                        
                        
                    else % if we are given str2 (input to function) does this even work??
                        obj.owner.(obj.variable).(obj.str2);
                    end

                catch ME
                    if isprop(obj.owner.(obj.self_name), 'latest_error')
                        obj.owner.(obj.self_name).latest_error = util.text.eraseTags(ME.getReport());
                    end
                    obj.owner.(obj.self_name).update;
                    rethrow(ME);
                end
            
            end
            
            obj.owner.(obj.self_name).update;
            
        end
        
        function callback_toggle(obj, ~, ~)
            
            if obj.owner.(obj.self_name).debug_bit, disp(['callback: ' obj.variable]); end

            if isprop(obj.owner.(obj.self_name), 'latest_error')
                obj.owner.(obj.self_name).latest_error = '';
            end

            if isprop(obj.owner.(obj.self_name), 'latest_warning')
                obj.owner.(obj.self_name).latest_warning = '';
                lastwarn('');
            end
            
            try

                val = obj.getVariable;
                obj.setVariable(~val);
    %             obj.owner.(obj.variable) = ~obj.owner.(obj.variable);

            catch ME
                if isprop(obj.owner.(obj.self_name), 'latest_error')
                    obj.owner.(obj.self_name).latest_error = util.text.eraseTags(ME.getReport());
                end
                obj.owner.(obj.self_name).update;
                rethrow(ME);
            end
            
            obj.owner.(obj.self_name).update;

        end
        
        function callback_auto(obj, ~, ~)
            
            if obj.owner.(obj.self_name).debug_bit, disp(['callback: ' obj.variable]); end
            
            if isprop(obj.owner.(obj.self_name), 'latest_error')
                obj.owner.(obj.self_name).latest_error = '';
            end

            if isprop(obj.owner.(obj.self_name), 'latest_warning')
                obj.owner.(obj.self_name).latest_warning = '';
                lastwarn('');
            end
            
            try
                
                val = obj.getVariable;

                if isempty(val)
                    obj.setVariable(0);
                elseif val
                    obj.setVariable([]);
                elseif ~val
                    obj.setVariable(1);
                end
            
            catch ME
                if isprop(obj.owner.(obj.self_name), 'latest_error')
                    obj.owner.(obj.self_name).latest_error = util.text.eraseTags(ME.getReport());
                end
                obj.owner.(obj.self_name).update;
                rethrow(ME);
            end
                
            obj.owner.(obj.self_name).update;
            
        end
        
        function callback_input(obj, hndl, ~)
            
            value = util.text.extract_numbers(hndl.String);
            
            value = value{1};
            
            if obj.owner.(obj.self_name).debug_bit, disp(['callback: ' obj.variable '= ' num2str(value)]); end
            
            if isprop(obj.owner.(obj.self_name), 'latest_error')
                obj.owner.(obj.self_name).latest_error = '';
            end

            if isprop(obj.owner.(obj.self_name), 'latest_warning')
                obj.owner.(obj.self_name).latest_warning = '';
                lastwarn('');
            end
            
            try
                
                if isempty(value)
                    if isprop(obj.owner, ['default_' obj.variable]) || ismethod(obj.owner, ['default_' obj.variable])
                        obj.setVariable(obj.owner.(['default_' obj.variable]));
    %                     obj.owner.(obj.variable) = obj.owner.(['default_' obj.variable]);
                    else
                        obj.owner.(obj.variable) = [];
                    end
                else  
                    obj.setVariable(value);
    %                 obj.owner.(obj.variable) = value;
                end

            catch ME
                if isprop(obj.owner.(obj.self_name), 'latest_error')
                    obj.owner.(obj.self_name).latest_error = util.text.eraseTags(ME.getReport());
                end
                obj.owner.(obj.self_name).update;
                rethrow(ME);
            end     
            obj.owner.(obj.self_name).update;
            
        end
        
        function callback_input_text(obj, hndl, ~)
            
            str = hndl.String;
            substr = split(str, '=');
            value = strip(substr{end});
            
            if obj.owner.(obj.self_name).debug_bit, disp(['callback: ' obj.variable '= ' value]); end
            
            if isprop(obj.owner.(obj.self_name), 'latest_error')
                obj.owner.(obj.self_name).latest_error = '';
            end

            if isprop(obj.owner.(obj.self_name), 'latest_warning')
                obj.owner.(obj.self_name).latest_warning = '';
                lastwarn('');
            end
            
            try

                if isempty(value)
                    if isprop(obj.owner, ['default_' obj.variable]) || ismethod(obj.owner, ['default_' obj.variable])
                        obj.setVariable(['default_' obj.variable]);
                    else
                        obj.setVariable('');
                    end
                else                
                    obj.setVariable(value);
                end
                  
            catch ME
                if isprop(obj.owner.(obj.self_name), 'latest_error')
                    obj.owner.(obj.self_name).latest_error = util.text.eraseTags(ME.getReport());
                    obj.owner.(obj.self_name).update;
                end
                rethrow(ME);
            end     
                  
            obj.owner.(obj.self_name).update;
            
        end
        
        function callback_info(obj, ~, ~)
            
            if obj.owner.(obj.self_name).debug_bit, disp('callback: update'); end

            obj.owner.(obj.self_name).update;            
            
        end
        
    end
   
    methods(Static=true)
        
        function val = defaultColor
            val = 0.94*ones(1,3);
        end
        
    end
    
end