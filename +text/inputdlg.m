function R = inputdlg(str, value)
% Usage: R = inputdlg(str, value=5)
% Displays an input dialog with question text "str" and default value 5.
% User may hit return after entering info.
% 
% The user prints a new number and hits Enter, then this function returns 
% the number it reads from the input field. 
%
% If no number is given or if 'Cancel' is pressed, returns empty. 
%
% Taken shamelessly from https://www.mathworks.com/matlabcentral/newsreader/view_thread/295157
% Also added a cancel button! 

if nargin==0, help('util.text.inputdlg'); return; end

if nargin<2 || isempty(value)
    value = '5';
end

if ~ischar(value)
    value = num2str(value);
end

R = []; % In case the user closes the GUI.
S.fh = figure('units','pixels',...
              'position',[50 500 300 150],...
              'menubar','none',...
              'numbertitle','off',...
              'name','Input: ',...
              'resize','off');
S.tx = uicontrol('style', 'text',...
                 'units', 'pix',...
                 'position', [10 100 280 30],...
                 'string', str);
S.ed = uicontrol('style','edit',...
                 'units','pix',...
                'position',[10 60 280 30],...
                'string',value);
S.pb = uicontrol('style','pushbutton',...
                 'units','pix',...
                'position',[10 20 140 30],...
                'string','Enter',...
                'callback',{@pb_call});
S.cn = uicontrol('Style', 'pushbutton',...
                'units', 'pix',...
                'position',[150 20 140 30],...
                'string', 'Cancel',...
                'callback',{@cn_call});
set(S.ed,'call',@ed_call)
uicontrol(S.ed) % Make the editbox active.
uiwait(S.fh) % Prevent all other processes from starting until closed.

    function [] = pb_call(varargin)
%         R = str2double(get(S.ed,'string'));
        R = get(S.ed,'String');
        close(S.fh); % Closes the GUI, allows the new R to be returned.
    end

    function [] = ed_call(varargin)
        uicontrol(S.pb)
        drawnow
%         R = str2double(get(S.ed,'string'));
        if isvalid(S.ed)
            R = get(S.ed, 'String'); 
        else
            R = [];
        end
        close(gcbf)
    end
    
    function [] = cn_call(varargin)
        R = [];
        close(gcbf);
    end

end