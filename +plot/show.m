function hndl = show(M, varargin)

    import util.text.*;
    import util.stat.*;
    import util.plot.*;
    import util.fft.*;
    import util.img.*;
    
    if nargin<1
        disp('SHOW will display an image from a 3D matrix');
        fprintf('options: \n num_pix_corner (statistics) \n frame_number (which image to show) \n');
        fprintf(' bias/dyn (dynamic range) or use autodyn \n play (video) and delay (video rate) \n fancy (titles and all) or simple (fancy=0) \n');
        fprintf(' zoom (using util.plot.zoomcenter) input(1): factor, input(2): x, input(3):y \n log (for log scale of the absolute value) \n ');
        fprintf(' xvalues / yvalues (set the axis), aspect(vector), fftshift ("on"/"off") \n ');
        fprintf(' axis / axes (set the containing axes object), parent (set the parent figure/panel)\n');
        return;
    end
    
    if isa(M, 'img.DataSet')
        M = M.data;
    end

    M = real(M(:,:,:,1));

    % input checks
    assert(~isempty(M), 'the input matrix is empty...');
    if nnz(~isnan(M))==0 
        disp('the input matrix is all NaNs!');
        h = imagesc(zeros(size(M)));
        text(0.5, 0.5, 'All NaNs!', 'Units', 'Normalized', 'FontSize', 26, 'Color', 'red', 'HorizontalAlignment', 'center');
        
        if nargout>0
            hndl = h;
        end
        
        return;
        
    end
    
    if nnz(~isinf(M))==0
        disp('the input matrix is all Infs!');
        h = imagesc(zeros(size(M)));
        text(0.5, 0.5, 'All Infs!', 'Units', 'Normalized', 'FontSize', 26, 'Color', 'red', 'HorizontalAlignment', 'center');
        
        if nargout>0
            hndl = h;
        end
    
        return;
        
    end
    
    try % parse varargin doublets
        
        num_pix_corner = floor(min(size(M,1), size(M,2))/10);
        frame_number = 1;
        dynamic_range = [];
        bias_level = [];
        play_str = '';
        pause_length = 0.1;
        zoom_input = [];
        fancy = 1;
        ax = [];
        parent = [];
        log_scale = 0;
        auto_dynamic_range = 0;
        xval = 1:size(M,2);
        yval = 1:size(M,1);
        aspect_ratio = [1 1 1];
        fft_shift = 0;
        monochrome = 0;
        font_size = 18;
        
        if ~isempty(varargin) && mod(length(varargin),2)==1
            varargin{end+1} = 1; % positive approach
        end
        
        for ii = 1:2:length(varargin)
            
            if cs(varargin{ii},{'corner_pixels','num_pix_corner'})
                num_pix_corner = varargin{ii+1};
            elseif cs(varargin{ii}, {'frame_number', 'page_number'})
                frame_number = varargin{ii+1};
            elseif cs(varargin{ii},'dynamic_range')
                dynamic_range = varargin{ii+1};
            elseif cs(varargin{ii}, 'bias_level')
                bias_level = varargin{ii+1};
            elseif cs(varargin{ii}, 'play')
                play_str = varargin{ii+1};
            elseif cs(varargin{ii}, {'pause', 'delay'})
                pause_length = varargin{ii+1};
            elseif cs(varargin{ii}, 'zoom')
                zoom_input = varargin{ii+1};
            elseif cs(varargin{ii}, 'fancy')
                fancy = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'simple')
                fancy = ~parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'logarithmic')
                log_scale = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'autodyn')
                    auto_dynamic_range = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, {'axes','axis'})
                if isa(varargin{ii+1}, 'matlab.graphics.axis.Axes')
                    ax = varargin{ii+1};
                end
            elseif cs(varargin{ii}, 'parent')
                if ~isempty(varargin{ii+1}) && isvalid(varargin{ii+1})
                    parent = varargin{ii+1};
                end
            elseif cs(varargin{ii}, {'x_values', 'xvalues'})
                xval = varargin{ii+1};
            elseif cs(varargin{ii}, {'y_values', 'yvalues'})
                yval = varargin{ii+1};
            elseif cs(varargin{ii}, 'aspect_ratio')
                aspect_ratio = varargin{ii+1};
            elseif cs(varargin{ii}, 'fftshift')
                fft_shift = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, {'monochrome', 'grayscale'})
                monochrome = parse_bool(varargin{ii+1});
            elseif cs(varargin{ii}, 'font_size')
                font_size = varargin{ii+1};
            end
                        
        end
    
    catch ME
        rethrow(ME);
    end
    
    try % log scale
        if log_scale
            M = log10(abs(double(M))); 
        end
    catch ME
        rethrow(ME);
    end
    
    try % the aspect ratio
        if length(aspect_ratio)==1
            aspect_ratio = [aspect_ratio 1 1];
        elseif length(aspect_ratio)==2
            aspect_ratio = [aspect_ratio 1];
        end
    catch ME
        rethrow(ME);
    end
    
    try % fft shift
        if fft_shift
            M = fftshift2(M);
        end
    catch ME
        rethrow(ME);
    end
    
    try % handle the play vector
        
        if size(M,3)>1 && isempty(play_str)
            M = M(:,:,frame_number);
        elseif ~isempty(play_str)
            
            page_vec = [];
            
            if isnumeric(play_str) && isscalar(play_str)
                
                if play_str==1
                    page_vec = 1:size(M,3);
                end
                
            elseif isnumeric(play_str) && isvector(play_str)
                page_vec = play_str;                
            elseif ischar(play_str)
                
                if cs(play_str, {'all', 'on', 'yes'})
                    play_str = '1:end';
                end
                
                play_str = strrep(play_str, 'end', num2str(size(M,3)));
                
                eval(['page_vec = ' play_str ';']);
            
            end
                
        end
    
    catch ME
        rethrow(ME)
    end

    try % handle dynamic range stuff
        
        if ~isempty(auto_dynamic_range) && auto_dynamic_range && (isempty(bias_level) || isempty(dynamic_range))
            
            if isempty(play_str)
                AD = autodyn(M);
            else
                AD = autodyn(M(:,:,1));
            end
            
            if isempty(bias_level)
                bias_level = AD(1);
            end
            
            if isempty(dynamic_range)
                dynamic_range = AD(2);
            end
            
        else % if we don't use autodyn
            
            if isempty(bias_level)
                if isempty(play_str)
                    bias_level = min2(M);
                else
                    bias_level = min(M(:));
                end
            end
            
            if isempty(dynamic_range)
                if isempty(play_str)
                    dynamic_range = max2(M);
                else
                    dynamic_range = max(M(:));
                end
            end
            
        end
        
        dynamic_range = double(dynamic_range);
        bias_level = double(bias_level);
        
        if dynamic_range==0 && bias_level==0
            dynamic_range = 1;
        end
        
        if dynamic_range<=bias_level
            bias_level = 0.9*abs(dynamic_range)*sign(dynamic_range);
        end
        
    catch ME
        rethrow(ME)
    end
    
    try % get the axes object / parent figure
            
        if isempty(ax) && ~isempty(parent)
            ax = axes('Parent', parent, 'Visible', 'off');
        elseif ~isempty(ax) && ~isempty(parent) % if both are non-empty
            ax.Visible = 'off';
            ax.Parent = parent;
        elseif ~isempty(ax) && isempty(parent)
            % don't do anything...
        else % if both are empty
            ax = gca;
            ax.Visible = 'off';
        end
        
    catch ME
        rethrow(ME);
    end
        
    try % statistics
        
        MAX = [];
        MEAN = [];
        STD = [];
        CMEAN = [];
        CSTD = [];

        MAX = max2(M);
        MEAN = mean2(M);
        STD = sqrt(var2(M));
        if ~isempty(num_pix_corner) && size(M,1)>2*num_pix_corner && size(M,2)>2*num_pix_corner
            CMEAN = corner_mean(M, num_pix_corner);
            CSTD = corner_std(M, num_pix_corner);
        else
            CMEAN = mean2(M);
            CSTD = std2(double(M));
        end

        
    catch ME
        warning(ME.getReport);
    end

    if size(M,3)==1
        
        h = image(xval, yval, M, 'CDataMapping','scaled', 'Parent', ax, 'Visible', 'off');
        try
            caxis(ax, [bias_level, dynamic_range]);
        end
        ax.Visible = 'on';
        h.Visible = 'on';
        axis(ax, 'image');
        ax.DataAspectRatio = aspect_ratio;
        
        if monochrome
            colormap(ax, flip(gray));
        end
        
        if fancy
            
            colorbar(ax);
            title(ax, sprintf('mx=%g \\mu=%g \\sigma=%g c.\\mu=%g c.\\sigma=%g', MAX, MEAN, STD, CMEAN, CSTD), 'FontSize', font_size);
        
        else
            set(ax,'XTick',[]);
            set(ax,'YTick',[]);
        end
        
        if ~isempty(zoom_input)
            
            if iscell(zoom_input)
                if length(zoom_input)==1
                    zoom_input = zoom_input{1};
                elseif length(zoom_input)==2 && ischar(zoom_input{2})
                    factor = zoom_input{1};
                    pos = zoom_input{2};
                    if cs(pos, 'maximum')
                        [~,mx] = max2(M);
                        pos = fliplr(mx);
                    elseif cs(pos, 'minimum')
                        [~,mx] = min2(M);
                        pos = fliplr(mx);
                    elseif cs(pos, 'center')
                        pos = [ceil((size(M,2)+1)/2) ceil((size(M,1)+1)/2)];
                    end
                    
                    zoom_input = [factor, pos];
                    
                else
                    
                    zoom_input = cell2mat(zoom_input);
                    
                end
                
                
            end
            
            if length(zoom_input)==1
                zoomcenter(ax, ceil((size(M,1)+1)/2), ceil((size(M,2)+1)/2), zoom_input);
            elseif length(zoom_input)==2
                zoomcenter(ax, zoom_input(2), zoom_input(2), zoom_input(1));
            elseif length(zoom_input)==3
                zoomcenter(ax, zoom_input(2), zoom_input(3), zoom_input(1));
            end
        end
        
        ax.FontSize = font_size;
        
    else % for playback of multiple images
        
        for ii = page_vec
            
            h = image(xval, yval, M(:,:,ii),'CDataMapping','scaled', 'Parent', ax, 'Visible', 'off');
            caxis(ax, [bias_level, dynamic_range]);
            ax.Visible = 'on';
            h.Visible = 'on';
                        
            text(0.1,0.1,['frame: ' num2str(ii)], 'Units','Normalized','FontSize',14, 'Parent', ax);
            axis(ax, 'image');
            ax.DataAspectRatio = aspect_ratio;
            
            ax.FontSize = font_size;
            if fancy
                
                title(ax, sprintf('mx=%s \\mu=%s \\sigma=%s c.\\mu=%s c.\\sigma=%s', ...
                    num2str(MAX(ii)), num2str(MEAN(ii)), num2str(STD(ii)), ...
                    num2str(CMEAN(ii)), num2str(CSTD(ii))),'FontSize', font_size);
                
                colorbar(ax);
        
            else
                set(ax,'XTick',[]);
                set(ax,'YTick',[]);
            end
            
            if ~isempty(zoom_input)
                                
                if iscell(zoom_input)
                    if length(zoom_input)==1
                        zoom_input = zoom_input{1};
                    elseif length(zoom_input)==2 && ischar(zoom_input{2})
                        factor = zoom_input{1};
                        pos = zoom_input{2};
                        if cs(pos, 'maximum')
                            [~,mx] = max2(M(:,:,ii));
                            pos = fliplr(mx);
                        elseif cs(pos, 'minimum')
                            [~,mx] = min2(M(:,:,ii));
                            pos = fliplr(mx);
                        elseif cs(pos, 'center')
                            pos = [ceil((size(M,2)+1)/2) ceil((size(M,1)+1)/2)];
                        end
                        
                        zoom_input_temp = [factor, pos];
                        
                    else
                        
                        zoom_input_temp = cell2mat(zoom_input_temp);
                        
                    end
                   
                else
                    zoom_input_temp = zoom_input;
                end
                        
                if length(zoom_input_temp)==1
                    zoomcenter(ax, floor(size(M(:,:,ii),1)/2), floor(size(M(:,:,ii),2)/2), zoom_input_temp);
                elseif length(zoom_input_temp)==2
                    zoomcenter(ax, zoom_input_temp(2), zoom_input_temp(2), zoom_input_temp(1));
                elseif length(zoom_input_temp)==3
                    zoomcenter(ax, zoom_input_temp(2), zoom_input_temp(3), zoom_input_temp(1));
                end
            end
            
            pause(pause_length);
            drawnow;
            
        end % for ii
        
    end
       
    if nargout>0
        hndl = h;
    end

end