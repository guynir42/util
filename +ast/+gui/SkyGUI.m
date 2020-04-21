classdef SkyGUI < handle
    
    properties 
        
        owner@util.ast.SkyMap; % link back to containg object

        fig@util.plot.FigHandler;
             
        buttons = {};
        menus = {};
        
        latest_error = '';
        latest_warning = '';
        
        font_size = 12;
        big_font_size = 16;
        edit_font_size = 11;
        small_font_size = 10;
        
        color_on = [0 0.3 1];
        
        debug_bit = 1;
        
    end
    
    properties % gui stuff
        
        menu_options;
        
        panel_controls;
        
        panel_contrast; % do we really need this??
        
        panel_close;
        button_close;
        
        panel_image;
        button_reset_axes;
        button_get_time;
        axes_image;
    
    end
    
    properties (Hidden=true)
              
        version = 1.00;
        
    end
            
    methods % constructor
       
        function obj = SkyGUI(owner)
            
            % later add other options like copy constructor
            if isa(owner, 'util.ast.SkyMap')
                
                if obj.debug_bit, fprintf('SkyGUI constructor v%4.2f\n', obj.version); end
                
                obj.owner = owner;
                
            else
                error('Input a util.ast.SkyMap to constructor of SkyGUI!');
            end
            
        end
        
    end
    
    methods % make/update/check GUI
    
        function make(obj)
            
            import util.plot.GraphicButton;
            import util.plot.GraphicPanel;
            import util.plot.ContrastLimits;
            import util.plot.MenuItem;
            
            obj.buttons = {};
            obj.menus = {};
            
            obj.fig = util.plot.FigHandler('Sky Map');
            obj.fig.clear;
            obj.fig.bottom = 5;
            obj.fig.height = 16;
            obj.fig.width = 32;
            movegui(obj.fig.fig, 'center');
            
            
            %%%%%%%%%%%%%%%%%%%%%%% MENUS %%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            % MenuItem(parent, text, type, variable, tooltip, separator)
            % obj.addButton(name, text, type, variable, tooltip, separator)
            % menu types: menu, toggle, push, input, input_text, info, custom
            
            obj.menu_options = MenuItem(obj, '&Options', 'menu'); 
            obj.menu_options.addButton('button_reset', '&Reset', 'custom', '', 'Reset all cuts on data to default values (maximal range)');
            
            obj.menu_options.button_reset.Callback = @obj.callback_reset;
            
            N = 10; % number of buttons on left side
            
            %%%%%%%%%%% panel controls %%%%%%%%%%%%%%%
            
            % Add buttons using obj.addButton(button_name, var_name='', type='', str1='', str2='', font_size='', split=1, color_on=[], color_off=[], tooltip)
            
            num_buttons = 6;
            obj.panel_controls = GraphicPanel(obj.owner, [0 (N-num_buttons)/N 0.2 num_buttons/N], 'controls', 1); % last input is for vertical (default)
            obj.panel_controls.addButton('button_min_mag', 'show_brightest_magnitude', 'input', 'M_min= ', '', '', 0.5, '', '', 'Minimal magnitude (brightest) to show'); 
            obj.panel_controls.addButton('button_max_mag', 'show_faintest_magnitude', 'input', 'M_max= ', '', '', 0.5, '', '', 'Maximal magnitude (faintest) to show'); 
            obj.panel_controls.addButton('button_min_mag', 'show_biggest_size', 'input', 'size= ', ' uas', '', 1, '', '', 'Biggest size of stars to show (micro arcsec)'); 
            obj.panel_controls.addButton('button_south', 'show_south_limit', 'input', 'south limit= ', ' deg', '', 1, '', '', 'How far south in declination to draw the map'); 
            obj.panel_controls.addButton('button_log', 'show_log', 'toggle', 'linear scale', 'log scale', '', 0.5, '', '', 'Show the map in linear/log scale');
            obj.panel_controls.addButton('button_cosine', 'use_cosine', 'toggle', 'cosine', 'cosine', '', 0.5, 'blue', '', '');
            obj.panel_controls.addButton('button_ecliptic', 'show_ecliptic', 'toggle', 'ecliptic', 'ecliptic', '', 0.5, 'blue', '', 'Show the ecliptic coordinates grid overlay');
            obj.panel_controls.addButton('button_ecliptic', 'show_galactic', 'toggle', 'galactic', 'galactic', '', 0.5, 'blue', '', 'Show the galactic coordinates grid overlay');            
            obj.panel_controls.addButton('button_ra_units', 'show_ra_units', 'custom', '', '', '', 0.5, '', '', 'Choose "degrees" or "hours" for the RA coordinate axis');
            obj.panel_controls.addButton('button_grid', 'show_grid', 'toggle', 'grid', 'grid', '', 0.5, 'blue', '', 'Show the time zone overlay');
            obj.panel_controls.number = num_buttons;
%             obj.panel_controls.margin = [0.03 0.02];
            obj.panel_controls.make;
            
            obj.panel_controls.button_ra_units.control.Style = 'popupmenu';
            obj.panel_controls.button_ra_units.control.String = {'degrees', 'hours'};
            obj.panel_controls.button_ra_units.Callback = @obj.callback_units_picker;
            
            %%%%%%%%%%% panel contrast %%%%%%%%%%%%%%%
            
            obj.panel_contrast = util.plot.ContrastLimits(obj.axes_image, obj.fig.fig, [0 1/N 0.2 3/N], 1); % last input is for vertical (default)
            obj.panel_contrast.font_size = obj.font_size;
            obj.panel_contrast.big_font_size = obj.big_font_size;
            obj.panel_contrast.small_font_size = obj.small_font_size;
            obj.panel_contrast.edit_font_size = obj.edit_font_size;
            
            %%%%%%%%%%% panel close %%%%%%%%%%%%%%%%%%
            
            obj.panel_close = uipanel('Position', [0 0 0.2 1/N]);
            obj.button_close = GraphicButton(obj.panel_close, [0 0 1 1], obj.owner, '', 'custom', 'CLOSE');
            obj.button_close.Callback = @obj.callback_close;
                        
            %%%%%%%%%%% panel image %%%%%%%%%%%%%%%%%%
            
            obj.panel_image = uipanel('Title', '', 'Position', [0.2 0 0.8 1]);
                        
            obj.makeAxes;
            
            obj.button_reset_axes = GraphicButton(obj.panel_image, [0.85 0.0 0.15 0.05], obj.owner, '', 'custom', 'new axes', '');
            obj.button_reset_axes.Callback = @obj.makeAxes;
            obj.button_reset_axes.Tooltip = 'Create a new image axis, zoomed out and with default contrast limits'; 
            obj.button_get_time = GraphicButton(obj.panel_image, [0 0 0.15 0.05], obj.owner, '', 'custom'); 
            obj.update;
            
        end
            
        function makeAxes(obj, ~, ~)
            
            delete(obj.axes_image);
            
            obj.axes_image = axes('Parent', obj.panel_image);
            
            obj.panel_contrast.ax = obj.axes_image;
%             colorbar(obj.axes_image);
            axis(obj.axes_image, 'image');
            
            obj.panel_contrast.ax = obj.axes_image;
            
        end
                
        function update(obj,~,~)
                        
            if ~obj.check
                return;
            end
           
            for ii = 1:length(obj.buttons)
                obj.buttons{ii}.update;
            end
            
            for ii = 1:length(obj.menus)
                obj.menus{ii}.update;
            end
            
            obj.panel_controls.button_ra_units.control.Value = find(strcmpi(obj.panel_controls.button_ra_units.control.String, obj.owner.show_ra_units));

            obj.button_get_time.String = 'working...';
            drawnow;
            
            t = tic;
            obj.owner.show('ax', obj.axes_image, 'font size', 20); 
            obj.button_get_time.String = sprintf('%4.2f sec', toc(t)); 
            
            obj.panel_contrast.min_val = 0;
            obj.panel_contrast.clim = [];
            obj.panel_contrast.update;
            
            
        end
                        
        function c = check(obj)
           
            c = ~isempty(obj) && ~isempty(obj.panel_close) && isvalid(obj.panel_close);
            
        end
        
    end
                
    methods % callbacks
        
        function callback_reset(obj, hndl, ~)
            
            if obj.debug_bit, disp('callback: reset'); end
            
            obj.owner.show_brightest_magnitude = [];
            obj.owner.show_faintest_magnitude = [];
            obj.owner.show_biggest_size = [];
            obj.owner.show_south_limit = [];
            
            obj.update;
            
        end
        
        function callback_units_picker(obj, hndl, ~)
            
            if obj.debug_bit, disp('callback: units picker'); end
            
            obj.owner.show_ra_units = hndl.String{hndl.Value};
            
            obj.update;
            
        end
        
        function callback_close(obj, ~, ~)
           
            if obj.debug_bit, disp('callback: close'); end
            
            delete(obj.fig.fig);
            
        end
        
    end
    
end