function [width, lines, pix_length, direction] = profile(M, varargin)

    import util.text.cs;
    import util.text.parse_bool;
    import util.plot.show;
    import util.plot.profile;
    import util.stat.max2;
    import util.stat.min2;
    import util.img.maskBadPixels;

    if nargin<1
        disp('PROFILE will display the cross section profile from a 2D matrix');
        fprintf('Options: \n center ("max", "center", [x y]) \n direction ("all", "xaxis", "yaxis", "min/max" number in degrees) \n ');
        fprintf('peak ("", "interp") \n width ("fwhm") \n number (frame number) \n ');
        fprintf('plot ("on", "off"), original("on", "off"), masking ("on", "off) \n');
        fprintf('axes (ax), fancy("on", "off"), legend("on", "off"), ratio (e.g. [1 1] \n');
        fprintf('plate scale ("nyquist" or numeric), binning\n');
        return;
    end

    if isa(M, 'img.DataSet')
        M = M.data;
    end
    
    M = M(:,:,:,1);

    assert(~isempty(M), 'the input matrix is empty...');
    
    
    try % parse varargin doublets    
    
        center = 'max';
        direction = 'all';
        peak = '';
        width_mode = 'fwhm';
        number = 1;
        plotting = 1;
        original = 0;
        masking = 0;
        ax = [];
        fancy = 1;
        use_legend = [];
        x_ax = [];
        y_ax = [];
        ax_title = [];
        ratio = [];
        plate_scale = [];
        binning = 1;
        font_size = get(0, 'DefaultTextFontSize');
        monochrome = 0;
        use_log = 0;
               
        if ~isempty(varargin) && mod(length(varargin),2)==1
            varargin{end+1} = 1; % positive approach
        end
        
        for ii = 1:2:length(varargin)
           
            if cs(varargin{ii}, 'center')
                center = varargin{ii+1};
            elseif cs(varargin{ii}, 'direction')
                direction = varargin{ii+1};
            elseif cs(varargin{ii}, 'peak')
                peak = varargin{ii+1};
            elseif cs(varargin{ii}, 'width')
                width_mode = varargin{ii+1};
            elseif cs(varargin{ii}, 'number')
                number = varargin{ii+1};
            elseif cs(varargin{ii}, {'plot', 'show', 'graphics'})
                plotting = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, {'original'})
                original = parse_bool(varargin{ii+1});                
            elseif cs(varargin{ii}, 'masking')
                masking = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, {'axes','axis'})
                ax = varargin{ii+1};
            elseif cs(varargin{ii}, 'fancy')
                fancy = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'legend')
                use_legend = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'xaxis')
                x_ax = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'yaxis')
                y_ax = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'title')
                ax_title = varargin{ii+1};
            elseif cs(varargin{ii}, {'aspect ratio', 'ratio'})
                ratio = varargin{ii+1};
            elseif cs(varargin{ii}, 'platescale')
                plate_scale = varargin{ii+1};
            elseif cs(varargin{ii}, 'binning')
                binning = varargin{ii+1};
            elseif cs(varargin{ii}, 'fontsize')
                font_size = varargin{ii+1};
            elseif cs(varargin{ii}, 'monochrome')
                monochrome = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'logarithmic')
                use_log = parse_bool(varargin{ii+1});
            end
            
        end
    
    catch ME
        rethrow(ME);
    end
    
    try % handle the number picker
        M = M(:,:,number);                
    catch ME
        rethrow(ME);
    end

    try % handle the masking of bad pixels
       
        if masking
            M = maskBadPixels(M);
        end
        
    catch ME
        rethrow(ME);
    end
        
    try % find the center point
        
        cen_x = [];
        cen_y = [];
        
        if isnumeric(center)
            
            assert(isvector(center) && length(center)==2, 'must input a 2 element vector for "center" or use "max" or "center" for center of image');
            cen_x = center(1);
            cen_y = center(2);
        elseif cs(center, 'maximum')
%             for ii=1:size(M,3)
                [~, mx] = max2(M(:,:,1));
                cen_x = mx(1);
                cen_y = mx(2);
%             end
        elseif cs(center, 'center')
            cen_x = ceil((size(M,2)+1)/2);
            cen_y = ceil((size(M,1)+1)/2);
        end
        
    catch ME
        rethrow(ME);
    end
    
    try % find the lines going through the image
            
        if isnumeric(direction)
            direction = num2cell(direction);
        else
        
            if ~iscell(direction)
                direction = {direction};
            end
            
            if cs(direction{1}, 'min')
                a = 0:179;
                w = profile(M, varargin{:}, 'dir', a, 'plot', 'off');
                [~, ind] = min(w);
                direction = {a(ind)};
            end

            if cs(direction{1}, 'max')
                a = 0:179;
                w = profile(M, varargin{:}, 'dir', a, 'plot', 'off');
                [~, ind] = max(w);
                direction = {a(ind)};
            end

            if cs(direction{1}, 'all')
                direction = {0,90,45};
            end

            for ii = 1:length(direction)

                if ischar(direction{ii}) && cs(direction{ii}, 'xaxis')
                    direction{ii} = 90;
                elseif ischar(direction{ii}) && cs(direction{ii}, 'yaxis')
                    direction{ii} = 0;
                end

            end
            
        end
        
    catch ME
        rethrow(ME);
    end
    
    try % find the set of indices for lines going through the image
        
        pix_length = [];
        
        for ii = 1:length(direction)
        
            direction{ii} = mod(direction{ii}, 180);
            
            x_vec = [];
            y_vec = [];
            if direction{ii}==0 || direction{ii}==180
                x_vec = 1:size(M,2);
                y_vec = ones(1,length(x_vec))*cen_y;
                pix_length(ii) = 1;
                
            elseif (direction{ii}>0 && direction{ii}<=45) || (direction{ii}>135 && direction{ii}<180)
                
                a = tand(direction{ii});
                b = cen_y-a*cen_x;
                x_vec = 1:size(M,2);
                y_vec = a*x_vec+b;
                y_vec(y_vec<1) = 1;
                y_vec(y_vec>size(M,1)) = size(M,1);
                y_vec = round(y_vec);
                pix_length(ii) = abs(1./cosd(direction{ii}));
                
            elseif (direction{ii}>45 && direction{ii}<90) || (direction{ii}>90 && direction{ii}<=135)
                                
                a = tand(direction{ii});
                b = cen_y-a*cen_x;
                y_vec = 1:size(M,1);
                x_vec = (y_vec-b)/a;
                x_vec(x_vec<1) = 1;
                x_vec(x_vec>size(M,2)) = size(M,2);
                x_vec = round(x_vec);
                x_vec = fliplr(x_vec);                
                y_vec = fliplr(y_vec);
                pix_length(ii) = abs(1./sind(direction{ii}));
                
            elseif direction{ii}==90
                y_vec = size(M,1):-1:1;
                x_vec = ones(1, length(y_vec))*cen_x;
                pix_length(ii) = 1;
            end
            
            indices{ii} = sub2ind(size(M), x_vec, y_vec);
                
        end
        
    catch ME
        rethrow(ME);
    end
    
    try % move to lines
        
        for ii = 1:length(indices)
            line_vec{ii} = M(indices{ii});                        
        end
        
    catch ME
        rethrow(ME);
    end 
    
    try % clip the peak if necessary
        
        if cs(peak, 'interp')
           
            for ii = 1:length(line_vec)
               
               [~,ind] = max(line_vec{ii});
               vec_ind = [1:ind-1 ind+1:length(line_vec{ii})];
               line_no_peak = line_vec{ii}(vec_ind);
               line_interp = interp1(vec_ind, line_no_peak, 1:length(line_vec{ii}), 'spline');
               line_vec{ii} = line_interp;
               
           end
           
        end
        
    catch ME
        rethrow(ME);
    end 
    
    try % find the widths
        
        if cs(width_mode, 'fwhm')
            for ii = 1:length(line_vec)
                factor=100;
                line_int = interp1(1:length(line_vec{ii}), line_vec{ii}, 1:1/factor:length(line_vec{ii}), 'spline');
                width(ii) = sum(line_int>max(line_int)/2)/factor.*pix_length(ii);
                if ~isempty(plate_scale) && isnumeric(plate_scale)
                    width(ii) = width(ii)*plate_scale/binning;
                elseif cs(plate_scale, 'nyquist')
                    width(ii) = width(ii)*0.5/binning;
                end
            end
        end
        
    catch ME
        rethrow(ME);
    end 

    direction = cell2mat(direction);
    
    if plotting==0, 
        
        lines = line_vec;
        return; 
    
    end % short circuit the end of the function if plotting is disabled...
    
    try % get some axes
        
        if isempty(ax)
            ax = gca;
        end
    catch ME
        rethrow(ME);
    end           
    
    try % set monochrome
       
        if monochrome
            ax.LineStyleOrder = '-|--|:|-.|-x|-*|-o|-p';
            ax.ColorOrder = [0 0 0];
        end
        
    catch ME
        rethrow(ME);        
    end
    
    try % plotting
        
        if original==0

            mx = 0;
            mn = 0;
            
            line_style_order = {'-','--',':','-.','-x','-*','-o','-p'};
            
            for ii = 1:length(indices)

                x_vec = (1:length(indices{ii}))-(floor(length(indices{ii})/2)+1);
                if ~isempty(plate_scale) && isnumeric(plate_scale)
                    x_vec = x_vec.*plate_scale/binning;
                elseif cs(plate_scale, 'nyquist')
                    x_vec = x_vec./2/binning;
                end
                
                if monochrome,
                    plot_str = ['k' line_style_order{mod(ii-1, length(line_style_order))+1}];
                else
                    plot_str  = '';
                end
                
                if use_log
                    lines(ii) = semilogy(ax, x_vec, line_vec{ii}, plot_str);
                else
                    lines(ii) = plot(ax, x_vec, line_vec{ii}, plot_str);
                end
                
                
                if mx<max(line_vec{ii}), mx = max(line_vec{ii}); end
                if mn>min(line_vec{ii}), mn = min(line_vec{ii}); end
                                
                ax.NextPlot = 'add';
                
            end
        
            ax.NextPlot = 'replace';

            if ~isempty(ratio)
                if length(ratio)<3
                    ratio = [ratio ones(1,length(ratio)-1)];
                end
                ax.PlotBoxAspectRatio = ratio;
            end

            if isempty(use_legend) % if no specifc value was chosen by the user
                use_legend = fancy;
            end
            
            if isempty(x_ax)
                x_ax = fancy;
            end
            
            if isempty(y_ax)
                y_ax = fancy;
            end
            
            if isempty(ax_title) && fancy
                title(ax, ['Image profile (through point: ' num2str(cen_x) ' ' num2str(cen_y) ')']);
            elseif cs(ax_title, 'off')
                title(ax, '');
            else
                title(ax, ax_title);
            end
            
            % fix the axis limits
            ax.XLim = [-Inf Inf];
            ax.YLim = [mn-abs(mn*0.01) mx+abs(mx*0.01)];
            
            if x_ax
                if isempty(plate_scale)
                    xlabel(ax, 'pixel number');
                elseif isnumeric(plate_scale)
                    xlabel(ax, '');
                    xtickformat(ax, '%g"');
                elseif cs(plate_scale, 'nyquist')
                    xlabel(ax, '');                    
                    for jj = 1:length(ax.XTickLabel)
                        ax.XTickLabel{jj} = ['$' num2str(ax.XTick(jj)) '\frac{\lambda}{D}$'];
                    end
                    ax.TickLabelInterpreter = 'latex';
                else
                    xlabel(ax, '');
                    for jj = 1:length(ax.XTickLabel)
                        ax.XTickLabel{jj} = [num2str(ax.XTick(jj)) '"'];
                    end
                end
            else
                ax.XTick = [];
            end
            
            if y_ax
                ylabel(ax, 'intensity');
            else
                ax.YTick = [];
            end
            
%             lines = findobj(ax, 'type', 'line');
            
            if use_legend 
                
                left_align = max(width)*1.5;
                right_align = x_vec(end)*0.95;
                top_align = max2(M);
                if isempty(plate_scale)
                    wid_units = 'px';
                elseif isnumeric(plate_scale)
                    wid_units = '"';
                elseif cs(plate_scale, 'nyquist')
                    wid_units = '\lambda/D';
                end
                
                leg_str = {};
                for ii = 1:length(lines)
                    leg_str{ii} = [sprintf('% 3d', direction(ii)) '\circ: ' num2str(width(ii)) wid_units];
                end
                                
                h = legend(ax, leg_str, 'Location', 'NorthEast', 'Units', 'Normalized', 'FontSize', font_size); 
                h.Box = 'off';
                
                
            end
            
        else % if original
            
            m = max2(M);
            for ii = 1:length(indices)
                M(indices{ii}) = 1.1*m;
            end
            
            show(M, 'axes', ax, 'fancy', fancy);
            if fancy, title(ax, ['Original image with profile lines at ' num2str(direction) ' degrees']); end
            
        end

    catch ME
        rethrow(ME);
    end  
    
        
end
        