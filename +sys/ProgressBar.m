classdef ProgressBar < handle
% Keeps track of time and prints out progress. 
% Before starting a potentially long calculation in a loop, generate an 
% object of this class:
% >> prog = util.sys.ProgressBar;
% Then start the timer and inform it how many iterations are coming: 
% >> prog.start(N);
% Inside the loop at the end of each iteration call:
% >> prog.show(ii) <or> prog.showif(ii) 
% This will print the progress bar and an estimate of the total runtime. 
% Using showif will only print out on iterations that are multiples of the
% "dividor" property, which depends on the total number of iterations N. 
% This makes sure the output is not crowded. 
% Use show() to always print the bar and estimate. 
% 
% Use finish() to finalize the progress bar after the last iteration and 
% also print the full progress bar with the total runtime. 
%
% Use pause() to stop the internal clock and upasue() to continue. 
% 
% Use
% TEST PROTOCOL: p=util.ProgressBar(100); p.showif(10); p.showif(100);

    properties
        
        start_time;
        stored_time;
        is_paused = 1;
        
        total_number;
        current_number;
        
        print_bit = 1;
                        
    end
    
    properties(Hidden=true)
        
    end
    
    properties(Dependent=true)
        
        dividor;
        
    end
    
    methods % constructor
        
        function obj = ProgressBar(total_number)
                                    
            if nargin>0 && ~isempty(total_number)
                obj.total_number = total_number;
            end
            
            obj.reset;
                     
            
        end
        
    end
    
    methods % getters
       
        function d = get.dividor(obj) % the dividor is rounded to 10's or 100's or more, so there are only a small number of outputs (<32) in the whole loop
           
            d = 10^round(log10(obj.total_number)-1); % round to the nearest power of 10 
            
%             if d<10
%                 d = 10;
%             end
            
        end
        
        function t = getElapsed(obj)
           
            if obj.is_paused
                t = obj.stored_time;
            else
                t = etime(clock, obj.start_time) + obj.stored_time;
            end
            
        end
        
    end
    
    methods % actions
                
        function start(obj, total_number) % start the timer and optionally give the number of iterations
               
            if nargin>1 && ~isempty(total_number)
                obj.total_number = total_number;
            end
            
            obj.reset(total_number);
            obj.unpause;
            
        end
        
        function finish(obj, number) % stop the timer and print the final (full) progress bar
        
            if nargin<2
                number = [];
            end
            
            obj.show(number);
            obj.pause;
            
        end
        
        function reset(obj, total_number) % clear all progress and stop the timer
            
            if nargin>1 && ~isempty(total_number)
                obj.total_number = total_number;
            end

            obj.stored_time = 0;
            obj.is_paused = 1;

            obj.current_number = 0;
            
        end
        
        function input(obj, number) % provide the current iterator number (can just use show() or showif() with that number)
            
            obj.current_number = number;
            
        end
                
        function pause(obj) % stop the timer but keep track of where we were
           
            obj.stored_time = obj.getElapsed;
            obj.start_time = clock;
            obj.is_paused = 1;
            
        end
        
        function unpause(obj) % resume running without reseting the elapsed time
           
            obj.start_time = clock;
            obj.is_paused = 0;
            
        end
        
        function advance(obj, step) % add one to the iterator
            
            if nargin<2 || isempty(step)
                step = 1;
            end
            
            obj.current_number = obj.current_number + step;
            
        end
        
    end
       
    methods % printing
        
        function f = frac(obj) % what fraction of the loop we are in
           
            if isempty(obj.total_number) || obj.total_number<1
                f = 0;
            else
                f = obj.current_number/obj.total_number;
            end
            
        end
        
        function str = show_bar(obj, number) % print the progress bar, e.g.,  [***      ]
                        
            if nargin>1 && ~isempty(number)
                obj.current_number = number;
            end
            
            str = sprintf('[%-64s]', repmat('*', 1, ceil(64*obj.frac)));
            
            if nargout<1
                disp(str);
            end
           
        end
        
        function str = show_current_time(obj, number) % print the current runtime in human formatted text
                        
            if nargin>1 && ~isempty(number)
                obj.current_number = number;
            end
            
            str = util.text.secs2hms(obj.getElapsed);
            
            if nargout<1
                disp(str);
            end
            
        end   
        
        function str = show_estimate_time(obj, number) % print the total estimated runtime in human formatted text
                        
            if nargin>1 && ~isempty(number)
                obj.current_number = number;
            end
            
            str = util.text.secs2hms(obj.getElapsed/obj.frac);
            
            if nargout<1
                disp(str);
            end
            
        end
                        
        function str_out = show(obj, number) % print the progress bar, current time, and total time estimate (optional input is the current iterator number)
                        
            if nargin>1 && ~isempty(number)
                obj.current_number = number;
            end
            
            str = [obj.show_bar ' ' obj.show_current_time ' / ' obj.show_estimate_time];
            
            if nargout<1 && obj.print_bit
                fprintf('\n');
                disp(str);
                fprintf('\n');
            else
                str_out = str;
            end
            
        end
        
        function showif(obj, number) % like show() but only print if the iterator is a round number (see dividor getter)
                  
            if nargin>1 && ~isempty(number)
                obj.current_number = number;
            end
                     
            if isempty(obj.total_number)
                return;
            end
            
            if obj.check(obj.current_number)
%                 obj.input(number);
                obj.show(obj.current_number);
            end
            
        end
        
        function c = check(obj, number) % check if the current iterator is divisible by "dividor"
            
            c = number>0 && mod(number, obj.dividor)==0;
            
        end
        
    end   
    
end