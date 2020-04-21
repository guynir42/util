classdef BolometricCorrections < handle
% Creates an interpolation object between color, temperature and bolometric correction. 
% Uses Eran's AstroUtil.spec.blackbody_mag_c and AstroUtil.spec.blackbody_bolmag
% 
% Usage: obj.makeSourceMatrix(filter1='BP', filter2='RP', filter_system='GAIA', mag_system='AB')
% This will generate the interpolation object. It takes some time (like 20 seconds). 
% After that you can quickly ask for bolometric corrections and temperature based on color. 
% The default is to use GAIA's BP-RP color. 
%
% To get the results use: obj.getTemp(color), make sure to use the right filters. Color can be a vector. 
% Can use the temperature to get bolometric correction (to be added to filter1) using obj.getBolCorr(temp). 
% Skip the temperature and get the bolometric correction from color using obj.getBolCorrFromColor(color). 

    properties
        
        filter1;
        filter2;
        
        temp_vec; % color estimated temperature
        color_vec; % color axis
        bol_corr_vec; % bolometric correction relative to filter1
        
    end
    
    methods
        
        function reset(obj)
            
            obj.filter1 = '';
            obj.filter2 = '';
            
            obj.temp_vec = [];
            obj.color_vec = [];
            obj.bol_corr_vec = [];
                        
        end
        
        function makeSourceMatrix(obj, filter1, filter2, filter_system, mag_system) % generate the temperature/bolometric correction vector we interpolate from 
            
            import AstroUtil.spec.blackbody_mag_c;
            import AstroUtil.spec.blackbody_bolmag;

            addpath(fullfile(util.def.data_folder));
            
            if nargin<2 || isempty(filter1)
                filter1 = 'BP';
            end
            
            if nargin<3 || isempty(filter2)
                filter2 = 'RP';
            end
            
            if nargin<4 || isempty(filter_system)
                filter_system = 'GAIA';
            end
            
            if nargin<5 || isempty(mag_system)
                mag_system = 'AB';
            end
            
            if isempty(filter1) || isempty(filter2)
                error('Must supply 2 non empty filters!');
            end
            
            filter_system1 = filter_system;
            filter_system2 = filter_system;
            
            obj.filter1 = filter1;
            obj.filter2 = filter2;
            
            if isnumeric(filter1)
                filter_system1 = filter1;
                filter1 = [];
            end
            
            if isnumeric(filter2)
                filter_system2 = filter2;
                filter1 = [];
            end
                
            tic;
            
            obj.temp_vec = (500:10:50000)';
            
            obj.color_vec = zeros(length(obj.temp_vec),1);
            obj.bol_corr_vec = zeros(length(obj.temp_vec),1);
            
            for ii = 1:length(obj.temp_vec)
                
                mag1 = blackbody_mag_c(obj.temp_vec(ii), filter_system1, filter1, mag_system);
                mag2 = blackbody_mag_c(obj.temp_vec(ii), filter_system2, filter2, mag_system);
                
                obj.color_vec(ii) =  mag1 - mag2;
                
                obj.bol_corr_vec(ii) = blackbody_bolmag(obj.temp_vec(ii))-mag1;
                                  
            end
            
            toc
            
        end
        
        function val = getTemp(obj, color) % interpolate the temperature from the color
            
            if isempty(obj.color_vec) || isempty(obj.temp_vec)
                obj.makeSourceMatrix(obj.filter1, obj.filter2);
            end
            
            val = interp1(obj.color_vec, obj.temp_vec, color);
            
        end
        
        function val = getBolCorr(obj, temp) % interpolate the bolometric correction from the temperature
            
            if isempty(obj.color_vec) || isempty(obj.temp_vec)
                obj.makeSourceMatrix(obj.filter1, obj.filter2);
            end
            
            val = interp1(obj.temp_vec, obj.bol_corr_vec, temp);
            
        end
        
        function val = getBolCorrFromColor(obj, color) % interpolate the bolometric correction from the color
            
            if isempty(obj.color_vec) || isempty(obj.temp_vec)
                obj.makeSourceMatrix(obj.filter1, obj.filter2);
            end
            
            val = interp1(obj.color_vec, obj.bol_corr_vec, color);
            
        end
        
    end
    
end