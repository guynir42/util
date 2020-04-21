function new_obj = full_copy(obj)
% Usage: new_obj = full_copy(obj). 
% Makes a deep copy of an object. 
% Uses the byte-stream built in Matlab function used (but not officially 
% documented) that is also used when saving MAT files. 
    
    if nargin==0, help('util.oop.full_copy'); return; end
    
    objByteArray = getByteStreamFromArray(obj);
    new_obj = getArrayFromByteStream(objByteArray);
    
end