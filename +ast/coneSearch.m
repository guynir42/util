function CatTable = coneSearch(RA, Dec, varargin)
% Usage: CatTable = coneSearch(obj, RA, Dec, radius_arcsec=100, varargin)
% Uses Eran's catsHTM to do a cone search on the coordinates RA/Dec in some
% radius, returning the catalog in a table format. 
%
% Inputs: RA and Dec can be given in degrees or sexagesimal strings.
%         
% Output: A table with the returned catalog. 
%
% Optional arguments:
%   -Radius: for the cone search, given in arcsec (default 100"). 
%   -Source catalog: What catalog to load from, default is GAIADR2. 
%   -Bolometric: If true will generate bolometric corrections for all stars 
%                in the field. Can also give a BolometricCorrections object
%                so it doesn't need to be regenerated each time (which is 
%                somewhat expensive as it needs to create the lookup table).
%
%   -Mag limit: Discard all stars dimmer than the magnitude limit. Must
%               define at least filter1 or filter2 (or both). 
% 

    if nargin==0, help('util.ast.coneSearch'); return; end

    input = util.text.InputVars;
    input.use_ordered_numeric = 1;
    input.input_var('radius', 100); 
    input.input_var('source', 'GAIADR2', 'catalog');
    input.input_var('bolometric', 0); 
    input.input_var('filter1', 'BP');
    input.input_var('filter2', 'RP');
    input.input_var('filter_system', 'GAIA'); 
    input.input_var('mag_limit', []); 
    input.scan_vars(varargin{:});

    if strcmpi(input.source, 'GAIADR2')
        addpath(fullfile(util.def.data_folder, 'GAIA/DR2'));
    end
    
    if isnumeric(RA)
        RA = RA.*pi/180;
    end
    
    if isnumeric(Dec)
        Dec = Dec.*pi/180;
    end
    
    [Cat, cols] = catsHTM.cone_search(input.source, RA, Dec, input.radius);

    CatTable = array2table(Cat, 'VariableNames', cols); 
    
    CatTable = CatTable(~isnan(CatTable{:,['Mag_' input.filter1]}),:);
    
    if ~isempty(input.mag_limit)
        CatTable = CatTable(CatTable{:,['Mag_' input.filter1]}<input.mag_limit,:);
        CatTable = CatTable(CatTable{:,['Mag_' input.filter2]}<input.mag_limit,:);
    end
    
    if isa(input.bolometric, 'util.ast.BolometricCorrections')
        bc = input.bolometric; % get the object from outside
    elseif util.text.parse_bool(input.bolometric) 
        bc = util.ast.BolometricCorrections; 
    else
        return;
    end
    
    %%%%% this part is only reached if we want to do bolometric corrections %%%%%%
    if isempty(bc.temp_vec) || isempty(bc.color_vec)
        bc.makeSourceMatrix(input.filter1, input.filter2, input.filter_system); % this takes about 20 seconds to do
    end
    
    mag1 = ['Mag_' input.filter1];
    mag2 = ['Mag_' input.filter2];
    
    temperatures = bc.getTemp(CatTable{:,mag1}-CatTable{:,mag2});
    
    CatTable(:,'bol_temp') = array2table(temperatures);
    
    bol_corr = bc.getBolCorr(temperatures, input.filter1, input.filter_system);
    
    CatTable(:,'bol_mag') = array2table(CatTable{:, mag1}+bol_corr);
    
    
end











