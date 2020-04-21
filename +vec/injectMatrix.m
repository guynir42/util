% Usage: injectMatrix(M_in_place, M_new, index)
% Replace the values in the first input with the values in the second input, 
% injecting them in the position pointed to by index (3rd input).
% This is equivalent to the assignment (S is the size of the new matrix): 
% >> M_in_place(index(1):index(1)+size(1)-1,index(2):index(2)+size(2)-1,...)=M_new; 
% The advantage of this function is that it can operate inside other functions
% and modify the inputs without making a copy of the array and returning it. 
%
% The copy is done in place, so no output is given. 
%
% WARNING: this can change other copies of M_in_place that share the underlying
%          memory. If you copied this matrix from another variable, make sure
%          to unshare them (e.g., by doing A(1)=A(1) before feeding A to this
%          function). 
%
% Can work on any numeric/logical data type, and any dimensionality. 
%
% Limitations: -Cannot handle complex numbers. 
%              -The third input "index" must have a number of elements equal
%               to the dimensions of M_in_place. 
%               Exceptions to this rule are if M_in_place is 1 dimensional,
%               then "index" can have 1 or 2 elements. 
%               Also if "index" has trailing 1s, more than the actual number 
%               of dimensions of M_in_place, they are simply truncated. 
%              -The new matrix must fit into the old matrix when placed at 
%               position "index" (top left corner in all dimensions). 
% 