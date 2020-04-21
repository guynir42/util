#include "mex.h"
#include "matrix.h"
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <vector>
#include <cctype>

// dim[0] is y, dim[1] is x, dim[2] is frame number (and also y of offsets) and dim[3] is star number (and also x of offsets)
// index convention is i=0...dim[0]-1, j=0...dim[1]-1, m=0...dim[2]-1, n=0...dim[3]-1
// index k is over dimensions k=0...ndims and the shorthand N is the number of elements in each image
// convert linear index inside "image" array using: image(i+1,j+1,m+1,n+1) ==> image[n*dim[0]*dim[1]*dim[2]+m*dim[0]*dim[1]+j*dim[0]+i];

void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] ){

	// check inputs!
	// if (nrhs==0){
		// mexPrintf("Usage: image_shifted = shift(image, dx, dy, filler)\n"); 
		// return;
	// }
	
	if (nrhs==0){
		
		const char *string[1]={"util.img.shift"};
		mxArray *array[1]={mxCreateCharMatrixFromStrings(1, string)};
		mexCallMATLAB(0,0,1,array,"help"); 
		return;
		
	}
	
	if(mxIsEmpty(prhs[0])){ // no input, then just return with all empty outputs...
		const mwSize dims[]={0,0};
		plhs[0]=mxCreateNumericArray(0,dims, mxDOUBLE_CLASS, mxREAL); // return all empty arrays...
		return;
	}

	if(nrhs<3 || mxIsEmpty(prhs[1]) || mxIsEmpty(prhs[2])) mexErrMsgIdAndTxt("MATLAB:util:img:shift:notEnoughInputs", "Not enough inputs to shift function!");
	
	// get dimensions of all inputs
	mwSize *dims_matlab=(mwSize*)mxGetDimensions(prhs[0]);
	int ndims=mxGetNumberOfDimensions(prhs[0]);	
	mwSize dims[4]={1,1,1,1}; // assume input is 4D and use dims[2]=1 and dims[3]=1 if not
	
	for(int k=0;k<ndims;k++){ 
		dims[k]=dims_matlab[k];
	}
	
	// mexPrintf("ndims= %d | dims[0]= %d | dims[1]= %d | dims[2]= %d | dims[3]= %d\n", ndims, dims[0], dims[1], dims[2], dims[3]);
	
	int N=dims[0]*dims[1]; // size of single image
	
	mwSize *dims_dx=(mwSize*)mxGetDimensions(prhs[1]);
	mwSize *dims_dy=(mwSize*)mxGetDimensions(prhs[2]);

	// check dimensions all agree
	if(dims_dx[0]!=dims_dy[0] || dims_dx[1]!=dims_dy[1]) mexErrMsgIdAndTxt("MATLAB:util:img:shift:offsetsWrongSize", "Inputs 2 and 3 must be the same size!");
	if(dims_dx[0]!=dims[2] || dims_dx[1]!=dims[3]) mexErrMsgIdAndTxt("MATLAB:util:img:shift:offsetsWrongSize", "Input 2 must have the same dimensions as 3rd and 4th dimension of input 1!");
	if(dims_dy[0]!=dims[2] || dims_dy[1]!=dims[3]) mexErrMsgIdAndTxt("MATLAB:util:img:shift:offsetsWrongSize", "Input 3 must have the same dimensions as 3rd and 4th dimension of input 1!");
	
	// read the offsets in x into a double array
	double **offsets_x=(double **)mxCalloc(dims[3], sizeof(double*));
	for(int n=0;n<dims[3];n++) offsets_x[n]=(double*) mxCalloc(dims[2], sizeof(double));
	
	if(mxIsClass(prhs[1], "single")){
		float *dx_float=(float*) mxGetData(prhs[1]);
		for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2]; m++) offsets_x[n][m]=dx_float[n*dims[2]+m];
	}
	else if(mxIsClass(prhs[1], "double")){
		double *dx_double=(double*) mxGetData(prhs[1]);
		for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2]; m++) offsets_x[n][m]=dx_double[n*dims[2]+m];
		
	}
	
	for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2]; m++){
		if(isnan(offsets_x[n][m])) offsets_x[n][m]=0;
		else offsets_x[n][m]=round(offsets_x[n][m]);
	}
	
	// read the offsets in y into a double array
	double **offsets_y=(double **)mxCalloc(dims[3], sizeof(double*));
	for(int n=0;n<dims[3];n++) offsets_y[n]=(double*) mxCalloc(dims[2], sizeof(double));
	
	if(mxIsClass(prhs[2], "single")){
		float *dy_float=(float*) mxGetData(prhs[2]);
		for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2]; m++) offsets_y[n][m]=dy_float[n*dims[2]+m];
	}
	else if(mxIsClass(prhs[2], "double")){
		double *dy_double=(double*) mxGetData(prhs[2]);
		for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2]; m++) offsets_y[n][m]=dy_double[n*dims[2]+m];
		
	}
	
	for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2]; m++){ 
		if(isnan(offsets_y[n][m])) offsets_y[n][m]=0;
		else offsets_y[n][m]=round(offsets_y[n][m]);
	}
	
	double filler=NAN; 
	if(mxIsClass(prhs[0], "single")==0 && mxIsClass(prhs[0], "double")==0) filler=0; // integer/boolean types must fill with zeros
	
	if(nrhs>3 && mxIsEmpty(prhs[3])==0){ // read the 4th input
	
		if(mxIsScalar(prhs[3])==0) mexErrMsgIdAndTxt("MATLAB:util:img:shift:fillerWrongSize", "Input 4 must be a numeric scalar!");
		
		filler=mxGetScalar(prhs[3]); 
		
	}
	
	////////////////// START THE SHIFTING //////////////////////
	if(mxIsClass(prhs[0], "single")){ // if we get single precision image
	
		float *image=(float*) mxGetData(prhs[0]); // get the underlying array
		plhs[0]=mxCreateNumericArray(4, dims, mxSINGLE_CLASS, mxREAL); // generate an output matrix
		float *image_shifted=(float*) mxGetData(plhs[0]); // get the array inside the output variable
		
		for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2];m++){ // go over all images/cutouts

			int start_index=n*dims[2]*dims[1]*dims[0]+m*dims[1]*dims[0];
			
			// mexPrintf("offsets_x[%d][%d]= %f | dims[1]= %d | result= %d\n", n, m, offsets_x[n][m], dims[1], offsets_x[n][m]<=-(int) dims[1]);
			
			if(offsets_x[n][m]==0 && offsets_y[n][m]==0){ // just copy, no shift required!
				// mexPrintf("Copy image as-is.\n");
				memcpy(&image_shifted[start_index], &image[start_index], N*sizeof(float));
			}
			else if(offsets_x[n][m]<=-(int)dims[1] || offsets_x[n][m]>=dims[1] || offsets_y[n][m]<=-(int)dims[0] || offsets_y[n][m]>=dims[0]){
				// mexPrintf("Placing filler in whole image\n");
				for(int i=0;i<N;i++) image_shifted[start_index+i]=filler; // just skip the whole image
			}
			else{
				for(int j=0;j<dims[1];j++){ // loop over columns
					
					// j is the x index in the OUTPUT IMAGE
					int jj=j-offsets_x[n][m]; // index for x in the INPUT IMAGE 
					
					if(jj<0 || jj>=dims[1]){ // column is outside the array
						// mexPrintf("j= %d, skipping\n", j);
						for(int i=0;i<dims[0];i++) image_shifted[start_index+j*dims[0]+i]=filler;
					}
					else{ // inside the array, copy the column with its own shifts
						// mexPrintf("j= %d, copying\n", j);
						if(offsets_y[n][m]==0) memcpy(&image_shifted[start_index+j*dims[0]], &image[start_index+jj*dims[0]], dims[0]*sizeof(float)); // copy the whole column
						else for(int i=0;i<dims[0];i++){ // copy the shifted part of the column
							
							int ii=i-offsets_y[n][m]; // index for y in the INPUT IMAGE
							
							if(ii<0 || ii>=dims[0]) image_shifted[start_index+j*dims[0]+i]=filler; // outside array
							else image_shifted[start_index+j*dims[0]+i]=image[start_index+jj*dims[0]+ii]; // copy the right place from the input array
							
						} // for i

					} // inside the array
						
				} // for j
			
			} // 
			
		}
	
	}
	else if(mxIsClass(prhs[0], "double")){ // if we get double precision image
	
		double *image=(double*) mxGetData(prhs[0]); // get the underlying array
		plhs[0]=mxCreateNumericArray(4, dims, mxDOUBLE_CLASS, mxREAL); // generate an output matrix
		double *image_shifted=(double*) mxGetData(plhs[0]); // get the array inside the output variable
		
		for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2];m++){ // go over all images/cutouts

			int start_index=n*dims[2]*dims[1]*dims[0]+m*dims[1]*dims[0];
			
			// mexPrintf("offsets_x[%d][%d]= %f | dims[1]= %d | result= %d\n", n, m, offsets_x[n][m], dims[1], offsets_x[n][m]<=-(int) dims[1]);
			
			if(offsets_x[n][m]==0 && offsets_y[n][m]==0){ // just copy, no shift required!
				// mexPrintf("Copy image as-is.\n");
				memcpy(&image_shifted[start_index], &image[start_index], N*sizeof(double));
			}
			else if(offsets_x[n][m]<=-(int)dims[1] || offsets_x[n][m]>=dims[1] || offsets_y[n][m]<=-(int)dims[0] || offsets_y[n][m]>=dims[0]){
				// mexPrintf("Placing filler in whole image\n");
				for(int i=0;i<N;i++) image_shifted[start_index+i]=filler; // just skip the whole image
			}
			else{
				for(int j=0;j<dims[1];j++){ // loop over columns
					
					// j is the x index in the OUTPUT IMAGE
					int jj=j-offsets_x[n][m]; // index for x in the INPUT IMAGE 
					
					if(jj<0 || jj>=dims[1]){ // column is outside the array
						// mexPrintf("j= %d, skipping\n", j);
						for(int i=0;i<dims[0];i++) image_shifted[start_index+j*dims[0]+i]=filler;
					}
					else{ // inside the array, copy the column with its own shifts
						// mexPrintf("j= %d, copying\n", j);
						if(offsets_y[n][m]==0) memcpy(&image_shifted[start_index+j*dims[0]], &image[start_index+jj*dims[0]], dims[0]*sizeof(double)); // copy the whole column
						else for(int i=0;i<dims[0];i++){ // copy the shifted part of the column
							
							int ii=i-offsets_y[n][m]; // index for y in the INPUT IMAGE
							
							if(ii<0 || ii>=dims[0]) image_shifted[start_index+j*dims[0]+i]=filler; // outside array
							else image_shifted[start_index+j*dims[0]+i]=image[start_index+jj*dims[0]+ii]; // copy the right place from the input array
							
						} // for i

					} // inside the array
						
				} // for j
			
			} // 
			
		}
	
	}
	else if(mxIsClass(prhs[0], "uint16")){ // if we get unsigned 16 bit integer image
	
		unsigned short int *image=(unsigned short int*) mxGetData(prhs[0]); // get the underlying array
		plhs[0]=mxCreateNumericArray(4, dims, mxUINT16_CLASS, mxREAL); // generate an output matrix
		unsigned short int *image_shifted=(unsigned short int*) mxGetData(plhs[0]); // get the array inside the output variable
		
		for(int n=0;n<dims[3];n++) for(int m=0;m<dims[2];m++){ // go over all images/cutouts

			int start_index=n*dims[2]*dims[1]*dims[0]+m*dims[1]*dims[0];
			
			// mexPrintf("offsets_x[%d][%d]= %f | dims[1]= %d | result= %d\n", n, m, offsets_x[n][m], dims[1], offsets_x[n][m]<=-(int) dims[1]);
			
			if(offsets_x[n][m]==0 && offsets_y[n][m]==0){ // just copy, no shift required!
				// mexPrintf("Copy image as-is.\n");
				memcpy(&image_shifted[start_index], &image[start_index], N*sizeof(unsigned short int));
			}
			else if(offsets_x[n][m]<=-(int)dims[1] || offsets_x[n][m]>=dims[1] || offsets_y[n][m]<=-(int)dims[0] || offsets_y[n][m]>=dims[0]){
				// mexPrintf("Placing filler in whole image\n");
				for(int i=0;i<N;i++) image_shifted[start_index+i]=filler; // just skip the whole image
			}
			else{
				for(int j=0;j<dims[1];j++){ // loop over columns
					
					// j is the x index in the OUTPUT IMAGE
					int jj=j-offsets_x[n][m]; // index for x in the INPUT IMAGE 
					
					if(jj<0 || jj>=dims[1]){ // column is outside the array
						// mexPrintf("j= %d, skipping\n", j);
						for(int i=0;i<dims[0];i++) image_shifted[start_index+j*dims[0]+i]=filler;
					}
					else{ // inside the array, copy the column with its own shifts
						// mexPrintf("j= %d, copying\n", j);
						if(offsets_y[n][m]==0) memcpy(&image_shifted[start_index+j*dims[0]], &image[start_index+jj*dims[0]], dims[0]*sizeof(unsigned short int)); // copy the whole column
						else for(int i=0;i<dims[0];i++){ // copy the shifted part of the column
							
							int ii=i-offsets_y[n][m]; // index for y in the INPUT IMAGE
							
							if(ii<0 || ii>=dims[0]) image_shifted[start_index+j*dims[0]+i]=filler; // outside array
							else image_shifted[start_index+j*dims[0]+i]=image[start_index+jj*dims[0]+ii]; // copy the right place from the input array
							
						} // for i

					} // inside the array
						
				} // for j
			
			} // 
			
		}
	
	}
	else mexErrMsgIdAndTxt("MATLAB:util:img:shift:wrongDataType", "Image must be double, single or uint16 class.");
	// free intermidiate arrays
	mxFree(offsets_x);
	mxFree(offsets_y);
	
} // end of mex function 