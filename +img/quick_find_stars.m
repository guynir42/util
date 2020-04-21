function [table_props, I_reduced] = quick_find_stars(I, varargin)
% Usage: [table_props, I_reduced] = quick_find_stars(I, varargin)
% Finds all the stars in the image above some threshold, using regionprops
% 
% OPTIONAL ARGUMENTS:
% -number: Maximum number of stars to find. Default is Inf. 
% -dilate: How much to dilate each found star before subtracting it (default 9). 
% -psf_sigma: Estimate of the PSF gaussian width parameter (default 2).
% -mean: Estimate of the image mean (background). If empty will be calculated using im_stats.
% -std: Estimate of the image standard deviation. If empty will be calculated using im_stats.
% -sigma: Threshold for finding stars (after mean subtract and divide by std). Default 3.5.
% -saturation: Value of brightest pixel must be lower than this or else flag 1 is set. 
% -edges: Replace edges with NaN before finding stars. If empty will be dilate*2. 
% -fraction: of MX_twice or MX_half that must surpass MX to be counted as point-source or extended-source
% -unflagged: if true only leave rows which have flag==0 (Default is false: take all stars!)
%
%
% OUTPUTS: 
% -table_props: output from regionprops in a table, along with positions 
%               (centroids), flux and flag for each star. 
% I_reduced: the image with found stars replaced with NaNs. 
% 
% NOTE: flag values are given as:
% 0- No flag, star is ok. 
% 1- Saturated star
% 2- Better fit to point source. 
% 3- Better fit to extended source. 
% ...
%

    if nargin==0, help('util.img.quick_find_stars'); return; end

    input = util.text.InputVars;
    input.input_var('number', [], 'max_number', 'num_stars'); 
    input.input_var('dilate', 9);
    input.input_var('psf_sigma', 2);
    input.input_var('mean', []);
    input.input_var('std', []);
    input.input_var('sigma', 5, 'threshold');
    input.input_var('saturation', 5e6); % saturation by default for 100 images in a stack
    input.input_var('edges', []);
    input.input_var('fraction', 0.8); % fraction of MX_twice or MX_half that must surpass MX to be counted as point-source or extended-source
    input.input_var('unflagged', 0, 'flagged'); % only leave rows which have flag==0
    input.scan_vars(varargin{:});
    
    if isempty(input.edges)
        input.edges = input.dilate.*2;
    end
    
    if isempty(input.number)
        input.number = Inf;
    end
    
    if isempty(input.mean) || isempty(input.std)
        
        [M,V] = util.img.im_stats(I);
        
        if isempty(input.mean)
            input.mean = M;
        end
        
        if isempty(input.std)
            input.std = sqrt(V);
        end
        
    end
    
    I = regionfill(I, isnan(I));    
    I_reduced = I;
    
    I_reduced = (I_reduced-input.mean)./input.std;    
%     I_reduced = regionfill(I_reduced, isnan(I_reduced));
    
    if input.edges
        I_reduced = util.img.pad2size(util.img.crop2size(I_reduced, size(I)-input.edges.*2), size(I), NaN);
    end
    
    pos = [];
    flux = [];
    flag = [];
    table_props = table.empty;
    
    thresholds = input.sigma + [5 3 0];
    
    k = util.img.gaussian2(input.psf_sigma, 'norm', 2);
    k_half = util.img.gaussian2(input.psf_sigma./2, 'norm', 2, 'size', size(k));
    k_twice = util.img.gaussian2(input.psf_sigma.*2, 'norm', 2, 'size', size(k));

    for ii = 1:length(thresholds)
        
        I2 = I_reduced;
        I2(isnan(I2)) = 0;
        
        If = filter2(k, I2); % ./sqrt(util.stat.sum2(k)); 
        If_half = filter2(k_half, I2); % ./sqrt(util.stat.sum2(k_half));
        If_twice = filter2(k_twice, I2); % ./sqrt(util.stat.sum2(k_twice));

        BW = If>=thresholds(ii);
        
        if input.dilate>0
            BW_dilated = imdilate(BW, ones(input.dilate));
        else
            BW_dilated = BW;
        end

        T = regionprops('table', BW, I, 'WeightedCentroid', 'PixelValues', 'PixelIdxList'); 

        if ~isempty(T) && ~iscell(T{:,'PixelValues'}) % this happens when all regions are single-pixel
            T2 = T(:,'WeightedCentroid');
            T2{:,2} = num2cell(T.PixelValues);
            T2{:,3} = num2cell(T.PixelIdxList);
            T2.Properties.VariableNames{2} = 'PixelValues';
            T2.Properties.VariableNames{3} = 'PixelIdxList';
            T = T2;
        end
        
        N = height(T);

        if N>0
            
            F = cellfun(@sum, T.PixelValues);

            P = T.WeightedCentroid;
            
            MX = zeros(N,1);
            MX_f = zeros(N,1);
            MX_half = zeros(N,1);
            MX_twice = zeros(N,1);

            for jj = 1:N
                MX(jj) = nanmax(T.PixelValues{jj});
                MX_f(jj) = nanmax(If(T.PixelIdxList{jj}));
                MX_half(jj) = nanmax(If_half(T.PixelIdxList{jj}));
                MX_twice(jj) = nanmax(If_twice(T.PixelIdxList{jj}));
            end

            f = zeros(size(P,1),1);    
            f(MX_f<MX_half*input.fraction) = 2; % point source 
            f(MX_f<MX_twice*input.fraction) = 3; % extended object
            f(MX>input.saturation) = 1; % saturated star 

            pos = vertcat(pos, P);
            flux = vertcat(flux, F);
            flag = vertcat(flag, f);
            table_props = vertcat(table_props, T);

            I_reduced(BW_dilated) = NaN;
        
            if height(table_props)>input.number
                break; % shorten the run if we already found enough stars...
            end
            
        end
        
    end
    
    I_reduced = I_reduced.*input.std + input.mean; % rescale this back to the original values
    
    T2 = table(flux, flag);
    
    table_props = horzcat(T2, table_props);
    
    if input.unflagged
        table_props(logical(flag), :) = []; % remove all non-zero flag stars
    end
    
    table_props = sortrows(table_props, 1, 'descend');
    
    if ~isempty(table_props)

        table_props.Properties.VariableNames{'WeightedCentroid'} = 'pos';
        table_props = [table_props(:,'flux') table_props(:,'flag') table_props(:,'pos') table_props(:, 'PixelValues'), table_props(:, 'PixelIdxList')];

        if height(table_props)>input.number
            table_props = table_props(1:input.number, :);
        end

    end
    
end