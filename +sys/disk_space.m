function Gb = disk_space(filename)
% Usage: Gb = disk_space(filename)
% Checks the amount of free space where file/folder is located. 
% Output is in Gigabytes! 
    
    if nargin==0, help('util.sys.disk_space'); return; end

    if ~exist(filename, 'file')
        filename = strsplit(filename, '/');
        filename = filename{1};
        filename = strsplit(filename, '\');
        filename = filename{1};
    end
    
    FileObj      = java.io.File(filename);
    free_bytes   = FileObj.getFreeSpace;
    total_bytes  = FileObj.getTotalSpace;
    usable_bytes = FileObj.getUsableSpace;

    Gb = free_bytes/1024.^3;

end