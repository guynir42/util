function print(filename, varargin)
% Usage: print(filename, varargin)
% Print the current figure into pdf, png, and eps given the string filename.
%
% filename should be without extension (extensions are added for each file type). 
% Optional arguments
%   -use_export: use the new +fig package based on XPDF
%   -resolution: for the old method
%   -use_screen: for the old method, instead of width/height
%   -height/width: for the old method, specify size of output. 
%   -fig: which figure to print (default is gcf). 
%
% This function requires the +util/+sys/+fig folder. 
% It needs to have ghostscript installed and XPDF needs to be told where it 
% was installed the first time (look for warning messages). 
% See license and readme in +fig folder for more info. 


            import util.sys.fig.export_fig;
            import util.text.cs;
            import util.text.parse_bool;
                        
            if nargin==0
                help('util.sys.print');
                return;
            end
            
            dir = fileparts(filename);
            
            if ~isempty(dir) && ~exist(dir, 'dir')
                error('No such directory: %s...', dir);
            end
                
            
            resolution = 0;
            height = [];
            width = [];
            use_screen = 0;
            fig = [];
            use_export = 1;
            
            for ii = 1:2:length(varargin)
               
                if cs(varargin{ii}, 'resolution')
                    resolution = varargin{ii+1};
                elseif cs(varargin{ii}, 'height')
                    height = varargin{ii+1};
                elseif cs(varargin{ii}, 'width')
                    width = varargin{ii+1};
                elseif cs(varargin{ii}, {'use_screen', 'screen'})
                    use_screen = parse_bool(varargin{ii+1});
                elseif cs(varargin{ii}, 'figure')
                    fig = varargin{ii+1};
                elseif cs(varargin{ii}, {'use_export', 'export'})
                    use_export = parse_bool(varargin{ii+1});
                end
                
            end
            
            if use_export

                try % export PNG
                    export_fig(filename,'-png', varargin{:});
                catch ME
                    warning(ME.getReport);
%                     print('-dpng', ['-r' num2str(resolution)], filename);
                end

                try % export PDF
                    export_fig(filename, '-pdf', varargin{:})
                catch ME
                    warning(ME.getReport);
%                     print(['-r' num2str(resolution)], filename, '-dpdf');
                end

%                 try % export EPS
%                     export_fig(filename,'-eps');
%                 catch ME
%                     warning(ME.getReport);
%                     print('-depsc', ['-r' num2str(resolution)], filename);
%                 end

            else % use the old "print" method

                if isempty(fig)
                    fig = gcf;
                end

                if isempty(width)
                    width = fig.OuterPosition(3); % cm
                end

                if isempty(height)
%                     height = width/2;
                    height = fig.OuterPosition(4)./fig.OuterPosition(3).*width; 
                end

                if use_screen
                    set(fig,'PaperPositionMode', 'auto');
                else
                    set(fig,'PaperPosition',[0,0,width,height]);
                end
                
                set(fig,'PaperSize',[width,height]);
                
                try
                    fig.PaperOrientation = 'portrait';
                    print(['-r' num2str(resolution)], filename, '-dpdf');
                catch ME
                    warning(ME.getReport);
                end

                try
                    fig.PaperOrientation = 'portrait';
                    print('-dpng', ['-r' num2str(resolution)], filename);
                catch ME
                    warning(ME.getReport);
                end

            end
            
%             if isunix, 
%                 system(['convert -density ' num2str(resolution) ' ' filename '.eps ' filename '.png']);
%             end
            
%             system(['epstopdf ' filename '.eps']);
            
        end