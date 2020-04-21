classdef GraphicPanel < dynamicprops
% Usage: GraphicPanel(owner, position, title='', is_vertical=1, self_name='gui')
% Container for GraphicButton objects. 
% Add buttons using obj.addButton(button_name, var_name='', type='', str1='', str2='', font_size='', split=1, color_on=[], color_off=[], tooltip)
% when you are done, use "make".
% The object creates and populates a uipanel with all the buttons. 

    properties
                
        owner; % the original owner of the GUI object (will own all buttons)
        self_name = 'gui'; % the name of the GUI inside of owner (e.g. if owner has multiple GUIs)
        buttons@util.plot.GraphicButton;
        
        title = '';
        is_vertical = 1; % if panel goes down or sideways. 
        number;
        
        list_of_button_details = struct('button_name', {}, 'var_name',{}, 'type', {}, 'str1', {}, 'str2', {}, 'font_size', {}, 'split', {}, 'color_on', {}, 'color_off', {}, 'tooltip', {}); 
        
        panel;
        position;
        margin;
        
    end
        
    methods 
        
        function obj = GraphicPanel(owner, position, title, is_vertical, self_name)
        % usage: GraphicPanel(owner, position, title='', is_vertical=1, self_name='gui')
        
            obj.owner = owner;           
            obj.position = position;
            
            if nargin>=3 && ~isempty(title)
                obj.title = title;
            end
            
            if nargin>=4 && ~isempty(is_vertical)
                obj.is_vertical = is_vertical;
            end
            
            if nargin>=5 && ~isempty(self_name)
                obj.self_name = self_name;
            end
                        
        end
        
        function addButton(obj, button_name, var_name, type, str1, str2, font_size, split, color_on, color_off, tooltip)
        % usage: obj.addButton(button_name, var_name='', type='', str1='', str2='', font_size='', split=1, color_on=[], color_off=[])
            
            if nargin<2, help('util.plot.GraphicPanel.addButton'); return; end
            
            if nargin<3 || isempty(var_name)
                var_name = '';
            end
            
            if nargin<4 || isempty(type)
                type = '';
            end
            
            if nargin<5 || isempty(str1)
                str1 = '';
            end
            
            if nargin<6 || isempty(str2)
                str2 = '';
            end
            
            if nargin<7 || isempty(font_size)
                font_size = '';
            end
            
            if nargin<8 || isempty(split)
                split = 1;
            end
            
            if nargin<9 || isempty(color_on)
                color_on = [];
            end
            
            if nargin<10 || isempty(color_off)
                color_off = [];
            end
            
            if nargin<11 || isempty(tooltip)
                tooltip = '';
            end
            
            obj.list_of_button_details(end+1) = struct('button_name', button_name, 'var_name', var_name, 'type', type,...
                'str1', str1, 'str2', str2, 'font_size', font_size, 'split', split, 'color_on', color_on, 'color_off', color_off, 'tooltip', tooltip);
            
        end
        
        function make(obj)
            
            list = obj.list_of_button_details;
            floors = {};
            index = 0;
            
            for ii = 1:length(list)
                                
                % check if we need to open a new floor (if button is not split)
                
                if index==0 || isempty(list(ii).split) || (sum([floors{index}.split])+list(ii).split)>1.01
                    index = index + 1;                    
                end
                
                if length(floors)<index || isempty(floors{index})
                    floors{index} = list(ii);
                else
                    floors{index} = [floors{index} list(ii)];
                end
                
%                 disp(['ii= ' num2str(ii) ' floors{' num2str(index) '}.split= ' util.text.print_vec([floors{index}.split])]);
                
            end
                        
            obj.panel = uipanel('Title', obj.title, 'Position', obj.position);
            N = max([obj.number length(floors)]);
                        
            for ii = 1:length(floors)
                    
                split_pos = 0;
                
                for jj = 1:length(floors{ii})
                    
                    button = floors{ii}(jj);
                        
                    if obj.is_vertical
                        pos = [split_pos (N-ii)/N button.split 1/N];
                    else
                        pos = [(ii-1)/N split_pos 1/N button.split];
                    end

                    if ~isprop(obj, button.button_name)
                        addprop(obj, button.button_name);
                    end
                    
                    obj.(button.button_name) = util.plot.GraphicButton(obj.panel, pos, obj.owner, button.var_name, button.type, button.str1, button.str2, ...
                        button.font_size, obj.self_name, [], button.color_on, button.color_off, button.tooltip, obj.margin);
                    
                    split_pos = split_pos + button.split;
                    
                    obj.buttons(end+1) = obj.(button.button_name);
                    
                end
                
            end
            
            obj.number = N;

        end
        
        function val = is_valid(obj)
            
            val = ~isempty(obj.panel) && isvalid(obj.panel);
            
        end
        
        function Enable(obj, val)
            
            for ii = 1:length(obj.buttons)
                obj.buttons(ii).Enable = val;
            end
            
        end
        
    end    
    
end