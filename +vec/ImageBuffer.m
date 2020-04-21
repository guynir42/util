classdef ImageBuffer < handle
% Stores a number of images, stacked in the 3rd dimension. 
% After stacking "N" images, the first ones are over-written by new images
% like a stack with a "first in, first out" rule. 
% This is useful for maintaining a sample of the latest images, throwing 
% away the old ones. 
% All images must be 2D of the same size and class. 
%
% Input the size of the buffer "N" as an optional argument to the constructor
% or to the reset() function, or set it in the object before filling it. 
% The default is N=10. 
% 
% Use "last" to get the last image added to the buffer. 
% Use "is_full" to test if the number of images reached or exceeded "N", 
% and use "is_empty" to check if no images were given at all. 
% 
% The "counter" tells how many images were added since the last reset(). 
% The "idx" tells what was the latest image index in the 3rd dimension. 
%
% The "im_size" gives the size of the 2D image dimensions.  
% 
 
    properties
        
        N = 10; % maximum number of images to store at any time
        idx = 0; % the last index where an image was added
        counter = 0; % the total number of images added since the last reset()
        
        im_size = []; % the size of the first 2 dimensions of the data
        
    end
    
    properties(Dependent=true)
        
        data;
        last;
        
    end
        
    properties(Hidden=true)
        
        raw_data = [];
        
    end
    
    methods
        
        function obj = ImageBuffer(varargin) % optional argument sets "N"
            
            input = util.text.InputVars;
            input.input_var('N', obj.N, 'number', 'length');
            input.use_ordered_numeric = 1;
            input.scan_vars(varargin{:});
            
            obj.N = input.N;
            
        end
        
        function reset(obj, N) % optional argument sets "N"
            
            if nargin>1 && ~isempty(N) && isnumeric(N) && N>0
                obj.N = N;
            end
            
            obj.raw_data = [];
            obj.idx = 0;
            obj.counter = 0;
            obj.im_size = [];
            
        end
        
        function input(obj, Im) % give a 2D matrix (all matrices must be the same size and class)
            
            if isempty(Im)
                return;
            end
            
            if ~ismatrix(Im)
                error('Must input a 2D image. Instead got %s', util.text.print_size(Im));
            end
            
            new_size = util.vec.imsize(Im);
            
            if isempty(obj.im_size)
                obj.im_size = new_size;
            elseif any(obj.im_size~=new_size)
                error('Size mismatch: %s', util.text.print_size(obj.im_size, new_size));
            end
            
            if isempty(obj.raw_data)
            
                obj.raw_data = zeros(new_size(1), new_size(2), obj.N);
                obj.idx = 1;
                obj.counter = 1;
                obj.raw_data(:,:,1) = Im;
                
            else
                
                obj.idx = obj.idx + 1;
                if obj.idx>obj.N
                    obj.idx = 1;
                end
                
                obj.counter = obj.counter + 1;
                
                obj.raw_data(:,:,obj.idx) = Im;
                
            end
            
        end
        
        function val = get.data(obj) 
            
            if isempty(obj.raw_data)
                val = [];
            else
                val = obj.raw_data(:,:,1:min(obj.N, obj.counter));
            end
            
        end
        
        function val = get.last(obj) % last image added to the buffer
            
            if isempty(obj.raw_data)
                val = [];
            else
                val = obj.raw_data(:,:,min(obj.N, obj.counter));
            end
            
        end
        
        function set.data(obj, val)
            
            obj.raw_data = val;
            
        end
        
        function val = is_full(obj) % if the number of images equals or exceeds "N"
            
            val = obj.counter>=obj.N;
            
        end
        
        function val = is_empty(obj) % if no images were added
            
            val = isempty(obj.data);
            
        end
        
    end
    
end