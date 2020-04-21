function RAM = free_ram(units)
% Usage: RAM = free_ram(units)
% Returns the amount of free RAM on this machine. 
% Tests indicate this is not a very accurate estimate. 
% Use the input "units" to specify if you want it in bytes, KBs, MBs or GBs

    import util.text.cs;

    if nargin==0, help('util.sys.free_ram'); return; end
    
    if ispc 
        M = memory;
        RAM = M.MaxPossibleArrayBytes;
    elseif isunix
        comm=' free | grep Mem | awk ''{print $4}'' ';
        [~, RAM] = unix(comm);
        RAM = str2num(RAM)*1024;        
    end
    
    if cs(units, 'bytes')
        % do nothing
    elseif cs(units, 'KBs', 'kilobytes')
        RAM = RAM/1024;
    elseif cs(units, 'MBs', 'megabytes')
        RAM = RAM/1024^2;
    elseif cs(units, 'GBs', 'gigabytes')
        RAM = RAM/1024^3;
    else
        error('Unknown unit type: "%s". Use "bytes" or "KBs" or "MBs" or "GBs"'); 
    end

end