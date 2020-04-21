#include "mex.h"
#include <stdio.h>
#include <cmath>
#include <string.h>

// Usage: injectMatrix(M_in_place, M_new, index)

void insert_2d(unsigned char *array_ip, const size_t *dims_ip, unsigned char *array_new, const size_t *dims_new, const size_t *index, const int num_bytes);
void insert_3d(unsigned char *array_ip, const size_t *dims_ip, unsigned char *array_new, const size_t *dims_new, const size_t *index, const int num_bytes);
void insert_nd(int N, unsigned char *array_ip, const size_t *dims_ip, unsigned char *array_new, const size_t *dims_new, const size_t *index, const int num_bytes);

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] ){

	if (nrhs==0){
		
		const char *string[1]={"util.vec.injectMatrix"};
		mxArray *array[1]={mxCreateCharMatrixFromStrings(1, string)};
		mexCallMATLAB(0,0,1,array,"help"); 
		return;
		
	}
	
	if(nrhs<2) mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:NotEnoughInuts", "Must supply at least two inputs!");
		
	mxArray *M_in_place=(mxArray*) prhs[0];
	const mxArray *M_new=prhs[1];
	size_t *index=0; 
	size_t index_dim=0;
	
	size_t num_bytes=0;
	// start checking inputs! 
	if(mxIsNumeric(M_in_place)==0 && mxIsLogical(M_in_place)==0) mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:InputNotNumeric", "Input 1 to function must be numeric or logical!");
	if(mxIsComplex(M_in_place)) mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:InputComplex", "Input 1 to function cannot be complex! ");
	num_bytes=mxGetElementSize(M_in_place);
	
	// printf("class of input 1 is: %s (needs %d bytes)...\n", mxGetClassName(M_in_place), num_bytes);
	
	if(mxIsEmpty(M_new)) return; // if we got an empty M_new there is nothing left to do to M_in_place! 
	if(mxGetClassID(M_in_place)!=mxGetClassID(M_new)) mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:InputsNotSameClass", "Inputs 1 and 2 must be the same class!");
	if(mxIsComplex(M_new)) mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:InputComplex", "Input 2 to function cannot be complex! ");
	
	const size_t ndims_ip_raw=mxGetNumberOfDimensions(M_in_place);
	const size_t *dims_ip_raw=mxGetDimensions(M_in_place);
	const size_t ndims_temp=mxGetNumberOfDimensions(M_new);
	const size_t *dims_temp=mxGetDimensions(M_new);
	size_t ndims_new=ndims_ip_raw;
	size_t *dims_new=(size_t*) mxCalloc(ndims_ip_raw, sizeof(size_t));
	for(int i=0;i<ndims_temp;i++) dims_new[i]=dims_temp[i]; // copy the first few dimensions
	for(int i=ndims_temp; i<ndims_ip_raw;i++) dims_new[i]=1; // add singleton dimensions if needed! 
	
	// printf("ndims_ip= %d\n", ndims_ip);
	// printf("dims_ip= ");
	// for(int i=0;i<ndims_ip; i++) printf("%d ", dims_ip[i]); 
	// printf("\n"); 
	
	// printf("ndims_new= %d\n", ndims_new);
	// printf("dims_new= ");
	// for(int i=0;i<ndims_new; i++) printf("%d ", dims_new[i]); 
	// printf("\n"); 
	
	if(nrhs>2){
		if(mxIsEmpty(prhs[2]) || mxIsClass(prhs[2], "double")==0 || mxGetM(prhs[2])>1) 
			mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:InputNotDouble", "Input 3 must be a double class row vector!");
		
		double *index_ptr=mxGetPr(prhs[2]); // double vector with the Input 3 array values
		index_dim=mxGetN(prhs[2]); // get the number of elements in the Input 3 vector! 
		index=(size_t*) mxCalloc(index_dim, sizeof(size_t)); // integer vector for the index
		for(int i=0;i<index_dim;i++) index[i]=(size_t) index_ptr[i]; 
		
		if(index_dim==1 && mxGetN(M_in_place)==1){ // input matrix is a column vector
			index_dim=2;
			index=(size_t*) mxCalloc(index_dim, sizeof(size_t));
			index[0]=(size_t) index_ptr[0]; // use the single value given from Input 3 as the first value in the 2-element index vector
			index[1]=1;
		}
		else if(index_dim==1 && mxGetM(M_in_place)==1){ // input matrix is a row vector
			index_dim=2;
			index=(size_t*) mxCalloc(index_dim, sizeof(size_t));
			index[0]=1;
			index[1]=(size_t) index_ptr[0]; // use the single value given from Input 3 as the second value in the 2-element index vector
		}
		else if(index_dim<ndims_ip_raw) mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:IndexSizeMismatch", "Input 3 must have a length as long as the number of dimesnions of input 1!");
		
		// check the values in "index" actually make sense... 
		for(int i=0;i<index_dim;i++) if(index[i]<1 || index[i]!=round(index[i])) 
			mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:IllegalIndex", "Input 3 must have integer, non-NaN values bigger than 0!");
	}
	else{ // didn't get a third input "index", use a vector of ones as default
		index_dim=mxGetNumberOfDimensions(M_in_place);
		index=(size_t*) mxCalloc(index_dim, sizeof(size_t)); 
		for(int i=0;i<index_dim;i++) index[i]=1; // use matlab style indices! 
	}
	
	size_t ndims_ip=ndims_ip_raw;
	size_t *dims_ip=(size_t*) dims_ip_raw; // shallow copy but why not (also, get rid of const) 
	if(index_dim>ndims_ip_raw){ // if "index" has more elements than the dimensions of M_in_place, we need to add singleton dimensions to M_in_place
		
		dims_ip=(size_t*) mxCalloc(index_dim, sizeof(size_t));
		for(int i=0;i<ndims_ip;i++) dims_ip[i]=dims_ip_raw[i]; // copy the first dimensions
		for(int i=ndims_ip;i<index_dim;i++) dims_ip[i]=1; // singletons 
		ndims_ip=index_dim; 
		
		ndims_new=ndims_ip; // update the M_new effective sizes with extra singletons, too!
		dims_new=(size_t*) mxCalloc(ndims_ip, sizeof(size_t));
		for(int i=0;i<ndims_new;i++) dims_new[i]=dims_temp[i]; // copy the first few dimensions
		for(int i=ndims_temp; i<ndims_ip;i++) dims_new[i]=1; // add singleton dimensions to the new size of dims_ip
		
	}
	
	// printf("index= ");
	// for(int i=0;i<index_dim;i++) printf("%d ", index[i]);
	// printf("\n"); 
	
	size_t *index_end=(size_t*) mxCalloc(index_dim, sizeof(size_t)); // another index vector specifying the ends of the matrix
	
	for(int i=0;i<index_dim;i++){
		if(i<ndims_new) index_end[i]=index[i]+dims_new[i]-1;
		else index_end[i]=index[i]; // singelton dimensions in M_new are allowed, treated as size=1... 
		if(index_end[i]>dims_ip[i]) mexErrMsgIdAndTxt("MATLAB:util:vec:injectMatrix:OutOfBounds", "Dimension %d exceeds the size of M_in_place!", i+1);
	}
	
	unsigned char *array_ip=(unsigned char *) mxGetData(M_in_place); 
	unsigned char *array_new=(unsigned char *) mxGetData(M_new); 
	
	if(ndims_ip==2)		
		insert_2d(array_ip, dims_ip, array_new, dims_new, index, num_bytes);
	else if(ndims_ip==3)		
		insert_3d(array_ip, dims_ip, array_new, dims_new, index, num_bytes);
	else if(ndims_ip>3)		
		insert_nd(ndims_ip, array_ip, dims_ip, array_new, dims_new, index, num_bytes);
	
}

void insert_2d(unsigned char *array_ip, const size_t *dims_ip, unsigned char *array_new, const size_t *dims_new, const size_t *index, const int num_bytes){ // arrays must be at least 2D and index/dims must include at least 2 elements! 
	
	for(int i=0;i<dims_new[1];i++){
		
		for(int j=0;j<dims_new[0];j++){
			memcpy(&array_ip[((i+index[1]-1)*dims_ip[0]+j+index[0]-1)*num_bytes], &array_new[(i*dims_new[0]+j)*num_bytes], num_bytes);
		}
		
	}
	
}

void insert_3d(unsigned char *array_ip, const size_t *dims_ip, unsigned char *array_new, const size_t *dims_new, const size_t *index, const int num_bytes){ // arrays must be at least 3D and index/dims must include at least 3 elements! 

	for(int i=0;i<dims_new[2];i++){
		
		insert_2d(&array_ip[(i+index[2]-1)*dims_ip[0]*dims_ip[1]*num_bytes], dims_ip, &array_new[i*dims_new[0]*dims_new[1]*num_bytes], dims_new, index, num_bytes);
		
	}

}

void insert_nd(int N, unsigned char *array_ip, const size_t *dims_ip, unsigned char *array_new, const size_t *dims_new, const size_t *index, const int num_bytes){ // arrays must be at least 3D and index/dims must include at least 3 elements! 

	if(N==3){ 
		insert_3d(array_ip, dims_ip, array_new, dims_new, index, num_bytes);
		return;
	}

	size_t block_size_ip=num_bytes;
	for(int i=0;i<N-1;i++) block_size_ip*=dims_ip[i];
		
	size_t block_size_new=num_bytes;
	for(int i=0;i<N-1;i++) block_size_new*=dims_new[i];
	
	for(int i=0; i<dims_new[N-1];i++)
		insert_nd(N-1, &array_ip[(i+index[N-1]-1)*block_size_ip], dims_ip, &array_new[i*block_size_new], dims_new, index, num_bytes);

}

