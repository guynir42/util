function C = unicode(name, number)
% Usage: C = unicode(name, number=0)
% Return a unicode character using its name. 
% Works for a bunch of names of things, clearly not all of them. 
% 
% If number is not zero, it will shift the resulting character from its
% regular position by <number> spots. E.g., unicode('dice', -2) will
% display a die with 4 instead of 6. 

    import util.text.cs;

    if nargin==0, help('util.text.unicode'); return; end

    if nargin<2 || isempty(number)
        number = 0;
    end
    
    if cs(name, 'play')
       H = '25b6';
    elseif cs(name, 'stop', 'square')
        H = '25A0';
    elseif cs(name, 'recycle')
       H = '267B';
    elseif cs(name, 'warning')
        H = '26A0';
    elseif cs(name, 'box')
        H = '2610';
    elseif cs(name, 'sun')
        H = '2609';
    elseif cs(name, 'earth')
        H = '2295';
    elseif cs(name, 'star')
        H = '2605';
    elseif cs(name, 'moon')
        H = '263E';
    elseif cs(name, 'pointing', 'finger')
        H = '261A';
    elseif cs(name, 'dice', 'die')
        H = '2685';
    elseif cs(name, 'no entry')
        H = '26D4';
    elseif cs(name, 'smiley')
        H = '263A';
    elseif cs(name, 'triangle')
        H = '26DB';
    else
        C = '';
        return;
    end
    
    D = hex2dec(H);
    
    C = char(D+number); 
    
end




