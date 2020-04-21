#include "mex.h"
#include "matrix.h"
#include <stdio.h>


void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] ){

	// check inputs
	if (nrhs==0){
		
		const char *string[1]={"util.vec.ndhist"};
		mxArray *array[1]={mxCreateCharMatrixFromStrings(1, string)};
		mexCallMATLAB(0,0,1,array,"help"); 
		return;
		
	}
	
	// get the first argument which the data to be histogrammed
	if(mxIsNumeric(prhs[0])==0 || mxIsClass(prhs[0], "single") && mxIsClass(prhs[0], "double") ) 
		mexErrMsgIdAndTxt("MATLAB:util:vec:ndhist:InputNotNumeric", "Input 1 to ndhist must be a numeric (float or double) matrix!");
	
	data=(float*) mxGetData(prhs[0]);
	mwSize *dims=(mwSize*)mxGetDimensions(prhs[0]);
	int ndims=(int) mxGetNumberOfDimensions(prhs[0]);	
	
	// check if the last input is also the output counts
	int num_axes=nrhs-1; 
	
	if(mxIsEmpty(prhs[num_axes])) 
	if(mxIsClass(prhs[num_axes], 'uint16') || mxIsClass(prhs[num_axes], 'uint32'))
	
	
	if(mxIsEmpty(prhs[0])){
		
		
	}
	
				  
				  
}