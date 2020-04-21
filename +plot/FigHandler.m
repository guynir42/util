classdef FigHandler < handle
% Wrapper for matlab's figure object. 
% Prevents new windows from popping up, but creates a new one if needed. 
%
% Use width and height (in cm) to set the size. 
% Use clear to remove all axes and other graphics. 
% Use the "fig" property to access the underlying figure. 
%
% EXAMPLE: f1=util.plot.FigHandler('test'); 


    properties
       
        fig@matlab.ui.Figure;
        
        debug_bit = 0;
        
        
    end
    
    properties(Hidden=true)
        
        version = 1.00;
        
    end
    
    properties(Dependent=true)
        
        isvalid;
        name;
        width;
        height;
        bottom;
        left;
        units;        
        
    end
    
    methods % constructor
        
        function obj = FigHandler(varargin)
            
            if ~isempty(varargin) && isa(varargin{1}, 'util.FigHandler') && ~isempty(varargin{1})
                
                obj.fig = varargin{1}.fig;
                if isempty(obj.fig) || ~isvalid(obj.fig)
                    obj.makeFigure;
                end
                
                obj.debug_bit = varargin{1}.debug_bit;
                
                obj.version = varargin{1}.version;
                
            elseif ~isempty(varargin) && isa(varargin{1}, 'matlab.ui.Figure')
               
                if obj.debug_bit, fprintf('FigHandler figure handle constructor v%4.2f\n', obj.version); end
                
                obj.fig = varargin{1};
                
            elseif ~isempty(varargin) && ischar(varargin{1})

                if obj.debug_bit, fprintf('FigHandler string constructor v%4.2f\n', obj.version); end
                
                obj.fig = matlab.ui.Figure.empty;
                obj.findFigure(varargin{1}, varargin{2:end});
                if isempty(obj.fig)
                    obj.makeFigure(varargin{1}, varargin{2:end});
                end
                
                
            else 
                                
                if obj.debug_bit, fprintf('FigHandler constructor v%4.2f\n', obj.version,2); end
                
                obj.makeFigure;
                
            end
            
            figure(obj.fig);
                        
            movegui(obj.fig, 'center');
            
        end
        
    end
    
    methods % actions
    
        function reset(obj)
            
            if ~obj.check
                obj.makeFigure(obj.name);
            end
            
            obj.fig.Units = 'Centimeters';
            obj.fig.Position = [24 10 24 10];
            figure(obj.fig);
            movegui(obj.fig, 'center');
            clf;
            obj.fig.Color = [1 1 1];
            
        end
        
        function clear(obj)
           
            if ~obj.check
                return;
            end
            
%             delete(obj.fig.Children);
            clf(obj.fig);

        end
        
        function parse(obj, varargin)
            
            % not yet implemented! 
            
        end
                
        function findFigure(obj, name, varargin)
        
            import util.text.cs
            
            list = get(groot, 'Children');
            
            for ii = 1:length(list)
               
                if cs(list(ii).Name, name)
                   
                    obj.fig = list(ii);
                    break;
                    
                end
                
            end
            
            obj.parse(varargin{:});
            
            obj.name = name;
            
        end
            
        function makeFigure(obj, name, varargin)
            
            obj.fig = figure;
            obj.reset;
            obj.parse(varargin{:});

            if nargin>1 && ~isempty(name) && ischar(name)
                obj.name = name;
                obj.fig.Name = name;
            end
            
        end
                
        function monochrome(obj, flip_bit)
           
            if ~obj.check
                return;
            end
            
            if nargin<2 || isempty(flip_bit)
                flip_bit = 1;
            end
            
            if flip_bit
                obj.fig.Colormap = flipud(gray);
            else
                obj.fig.Colormap = gray;
            end                
            
        end
        
        function colorize(obj, type)
                      
            if ~obj.check
                return;
            end
            
            if nargin<2 || isempty(type)
                type = 'parula';
            end
            
            colormap(obj.fig, type);
                        
            
        end
        
    end
    
    methods % getters
        
        function val = check(obj)
            
            val = ~isempty(obj.fig) && isvalid(obj.fig);
            
        end
        
        function val = get.isvalid(obj)
           
            val = obj.check;
            
        end
        
        function val = get.name(obj)
            if obj.check
                val = obj.fig.Name;
            else
                val = [];
            end
        end
        
        function val = get.width(obj)
            if obj.check
                val = obj.fig.Position;
                val = val(3);
            else
                val = [];
            end
        end
        
        function val = get.height(obj)
            if obj.check
                val = obj.fig.Position;
                val = val(4);
            else
                val = [];
            end
        end
                
        function val = get.bottom(obj)
            if obj.check
                val = obj.fig.Position;
                val = val(2);
            else
                val = [];
            end
        end
        
        function val = get.left(obj)
            if obj.check
                val = obj.fig.Position;
                val = val(1);
            else
                val = [];
            end
        end
        
        function val = get.units(obj)
            if obj.check
                val = obj.fig.Units;
            else
                val = [];
            end
        end
        
    end
    
    methods % setters
        
        function set.name(obj, val)
            
            if obj.check
                obj.fig.Name = val;
            end
            
        end
        
        function set.width(obj, val)
           
            if obj.check
               
                pos = obj.fig.Position;
                
                pos(3) = val;
                
                obj.fig.Position = pos;
                
            end
            
        end
        
        function set.height(obj, val)
           
            if obj.check
               
                pos = obj.fig.Position;
                
                pos(4) = val;
                
                obj.fig.Position = pos;
                
            end
            
        end
        
        function set.bottom(obj, val)
           
            if obj.check
               
                pos = obj.fig.Position;
                
                pos(2) = val;
                
                obj.fig.Position = pos;
                
            end
            
        end
        
        function set.left(obj, val)
           
            if obj.check
               
                pos = obj.fig.Position;
                
                pos(1) = val;
                
                obj.fig.Position = pos;
                
            end
            
        end
        
        function set.units(obj, val)
           
            import util.text.cs;
            
            if obj.check
                
                if cs(val, 'cm')
                    val = 'Centimeters';
                elseif cs(val, 'px')
                    val = 'Pixels';                
                end
                
                obj.fig.Units = val;
                
            end
            
        end
        
    end
    
end