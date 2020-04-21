#include "mex.h"

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] ){
	
	
	// check inputs!
	if (nrhs==0){ 
		mexPrintf("Usage: S = sum_singles(matrix)\n");
		mexPrintf("Takes inputs of types double, single and uint16 and returns a sum along the 3rd dimension in single precision.\n");
		return;
	}
	
	if(mxIsEmpty(prhs[0])){ // no input, then just return with all empty outputs...
		const mwSize dims[]={0,0};
		plhs[0]=mxCreateNumericArray(0,dims, mxSINGLE_CLASS, mxREAL); // return an empty array
		return;
	}

	
	mwSize *dims=(mwSize*)mxGetDimensions(prhs[0]); // dims[0] is the height while dims[1] is the width while dim[2] is the number of frames
	int ndims=mxGetNumberOfDimensions(prhs[0]);	
	
	if(ndims>3) mexErrMsgIdAndTxt("MATLAB:util:stat:sum_singles:inputMoreThan3D", "Input 1 to sum_singles should have at most 3 dimensions...");
	if(ndims<3){ 
		plhs[0]=mxDuplicateArray(prhs[0]);
		return;
	}
	
	mwSize dims_out[2]={dims[0], dims[1]};
	int N=dims_out[0]*dims_out[1]; // total size of output array 
	
	plhs[0]=mxCreateNumericArray(2, dims_out, mxSINGLE_CLASS, mxREAL); // create the output matrix (in matlab)
	float *output=(float*) mxGetData(plhs[0]); // get the C type array 
	
	if(mxIsClass(prhs[0], "double")){
		
		double *matrix=(double*) mxGetData(prhs[0]);
		
		for(int j=0;j<dims[2];j++){// go over all frames
		
			for(int i=0;i<N;i++){ //  go over pixels in each image
				
				output[i]+=matrix[j*N+i];
				
			} // for i (pixels in image)
			
		} // for j (frames)
		
	}
	else if(mxIsClass(prhs[0], "single")){
		
		float *matrix=(float*) mxGetData(prhs[0]);
		
		for(int j=0;j<dims[2];j++){// go over all frames
		
			for(int i=0;i<N;i++){ //  go over pixels in each image
				
				output[i]+=matrix[j*N+i];
				
			} // for i (pixels in image)
			
		} // for j (frames)
		
	}
	else if(mxIsClass(prhs[0], "uint16")){
		
		short unsigned int *matrix=(short unsigned int*) mxGetData(prhs[0]);
		
		for(int j=0;j<dims[2];j++){// go over all frames
		
			for(int i=0;i<N;i++){ //  go over pixels in each image
				
				output[i]+=matrix[j*N+i];
				
			} // for i (pixels in image)
			
		} // for j (frames)
		
	}
	else mexErrMsgIdAndTxt("MATLAB:util:stat:sum_singles:inputTypeUnrecognized", "Input 1 to sum_singles is not a double, single or uint16 array...");
	
}