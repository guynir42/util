#include "mex.h"
#define INDEX_VECTOR 0
#define INDEX_INDEX 1
#define INDEX_VALUE 2

// Usage: mex_change(mex_vector, index, [value])

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] ){

	if(nrhs<1){ // usage is detailed when function is called without arguments!
		const char *string[1]={"util.vec.mex_change"};
		mxArray *array[1]={mxCreateCharMatrixFromStrings(1, string)};
		mexCallMATLAB(0,0,1,array,"help"); 
		return;
	}
	
	if(nrhs<2) mexErrMsgIdAndTxt( "MATLAB:util:vec:mex_change:notEnoughInputs", "Need at least two inputs!");
		
	double *mex_vector=0;
	if(mxIsNumeric(prhs[INDEX_VECTOR])==0) 
		mexErrMsgIdAndTxt( "MATLAB:util:vec:mex_change:inputNotNumeric", "Input %d must be numeric!", INDEX_VECTOR+1);

	if(mxIsScalar(prhs[INDEX_VECTOR])) mex_vector= (double*)(long long int) mxGetScalar(prhs[INDEX_VECTOR]); // this needs to be carefully tested...
	else mex_vector=mxGetPr(prhs[INDEX_VECTOR]);
	
	if(mxIsNumeric(prhs[INDEX_INDEX])==0 || mxIsScalar(prhs[INDEX_INDEX])==0) 
		mexErrMsgIdAndTxt( "MATLAB:util:vec:mex_change:inputNotNumeric", "Input %d must be a numeric scalar!", INDEX_INDEX+1);
	
	int index=(int) mxGetScalar(prhs[INDEX_INDEX]);
	index--; // convert to C++ indices
		
	double value=mex_vector[index]+1; // default is just to ++ that element in the vector.
	if(nrhs>=3 && mxIsEmpty(prhs[INDEX_VALUE])==0){
		if(mxIsNumeric(prhs[INDEX_VALUE])==0 || mxIsScalar(prhs[INDEX_VALUE])==0)
			mexErrMsgIdAndTxt( "MATLAB:util:vec:mex_change:inputNotNumeric", "Input %d must be a numeric scalar!", INDEX_VALUE+1);
		
		value=mxGetScalar(prhs[INDEX_VALUE]); // if a numerical value is given
		
	}
	
	mex_vector[index]=value;
	
}