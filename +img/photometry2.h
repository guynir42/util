#ifndef PHOTOMETRY2_H
#define PHOTOMETRY2_H

#include <stdio.h>
#include <math.h>
#include <string.h>
#include <vector>
#include <cctype>
#include <thread>
#include <chrono>
#include <algorithm> 

#define STRLN 64 // maximum string length (for copying)
#define NUM_DATA_TYPES 10 // flux, area, error, background, variance, offset_x, offset_y, width, bad_pixels, flag

/* Usage: [outputs, arrays] = photometry2(cutouts, varargin)

Optional arguments: 
		*index: choose the photometry object number out of the array (index starts at 1!). 
		        This save preallocation of output arrays if you use photometry on different sized datasets in sequence. 
		*aperture or radius: a vector of aperture radii to be used for
                            aperture photometry (in pixels!). The biggest 
                            radius is also used for recentering (see
                            below) and for forced photometry. 
                            Default is [5,7,9].
       *gauss_sigma: the width of the gaussian used in PSF photometery.
                     Default is 2 pixels. 
       *annulus: a one or two element vector for the inner and outer
                 radius of the background annulus. If second element is
                 not given or is smaller than the first, assume it is
                 infinite (so all pixels above the first radius are used).
       *gain: This is used only to estimate the errors from source noise.
              Default is 1. 
       *scintillation_fraction: Used to estimate the additional noise
                                caused by intensity scintillation. This
                                also only affects error estimates. 
                                Default is 0.
       *resolution: How many shifts are needed for all the different
                    apertures/annuli/PSFs. When resolution is 1 (default)
                    the different masks are moved in steps of single
                    pixels, and if resolution is bigger than 1, use more
                    steps inside each pixel for the relative shifts of the
                    masks. The default is 1 but 2 is also a good choice,
                    and I don't think we need more than that.
                    Use only integer values. 
       *threads: how many physical cores should be used to split the work 
                 on different cutouts. For serious computers we should see
                 a speedup proportional to the number of threads for at
                 least threads<5. Default is 1 (no multithreading). 
       *iterations: How many repositions of the gaussians are used on each
                    cutout before settling on the results. Default: 2.
       *use_centering_aperture: If true, use a an aperture at the position
                                from the raw photometery, just to get a
                                little better positioning before going on
                                to the more narrow gaussian photometry. 
       *use_gaussian: If falue, skip gaussians altogether (default true).
       *use_apertures: If false, skip aperture photometery (default true).
       *use_forced: If false, skip doing forced photometry (default true). 
       *debug_bit: Level of verbosity of the code (default: 0). 

For more information about how to use this function, see photometry2.m

Updates:
2020-02-27 Guy: Added multiple objects in global scope, added parseIndex method to find which one to use. 
                This prevents users that do photometry on multiple data sets of differing size from resetting
				the whole preallocation mechanisms. 
				E.g., one photometry object is used for stack photometry and one for full-cutouts. 
				This way no need to reallocate the data twice each batch. 
				
				
Original code by Guy Nir Dec 2019

Additional developer notes after the header

*/

// utility functions to compare strings
bool cs(const char *keyword, const char *compare_str, int num_letters=3);
bool cs(const char *keyword, const char *str1, const char *str2, int num_letters=3);
bool cs(const char *keyword, const char *str1, const char *str2, const char *str3, int num_letters=3);
bool parse_bool(mxArray *value);
int parseIndex(int nrhs, const mxArray *prhs[]);

class Photometry{
	
	public:
		
	float *cutouts=0; // the input matrix on which we calculate everything (dim 1&2 are y&x, dim 3 is frame number, dim 4 is star number)
	mwSize dims[4]={0}; // array with the sizes of cutouts
	mwSize ndims=0; // number of dimensions of cutouts
	int num_cutouts=0;  // number of cutouts (dim 3 times dim 4)
	int N=0; // number of pixels in each cutout (dim 1 times dim 2)
	
	double gain=1; // calculate the source noise using the gain
	double scintillation_fraction=0; // use this to add the estimated scintillation noise (in fractions of the reduced flux)
	int num_threads=1; // for future use with built-in multithreading
	int num_iterations=2; // how many iterations of repositioning should we do
	bool use_centering_aperture=1; // run one level of aperture photometry (centroids only) before the first gaussian iterations
	bool use_gaussian=1; // decide if you want to use gaussians photometry at all
	bool use_apertures=1; // decide if you want to use aperture photometry (wedding cake)
	bool use_forced=1; // decide if you want to use forced photometry after finding the best offsets
	bool use_median=1; // decide if you want to use median (instead of mean) to get the background value
	
	int debug_bit=0;
	
	// these can be shared with all calculations (i.e., they are kept in memory between calls to photometry2!)
	float *X=0; // grid points not including shifts. 
	float *Y=0; // grid points not including shifts. 
	
	int resolution=1; // how many different aperture/gaussian shifts we want in each pixel
	mwSize shift_dims[2]={0}; // dimensions of shift matrices dx/dy	
	int num_shifts=0; // number of shifts we need to cover all possible star positions (i.e., the length of dx and dy, shift_dims[0]*shift_dims[1])
	float *dx=0; // list of offsets in x for the center of the mask
	float *dy=0; // list of offsets in y for the center of the mask
	
	float *forced=0; // 3D matrix of apertures used for forced photometry, one for each dx/dy shift
	std::vector<int> *forced_indices=0; // array of length "num_shifts" of index vectors telling what part of each matrix to sum in forced photometry
	double forced_radius=5; // the default radius used for forced photometry (pixels)

	float *apertures=0; // 4D matrix of aperture+annuli for the wedding cake photometry
	std::vector<int> *aperture_indices=0; // array of length "num_shifts" of index vectors telling what part of each matrix to sum in wedding cake photometry
	int num_radii=0; // how many different aperture arrays do we have for the wedding cake
	double *ap_radii=0; // radii of different apertures, given in pixel units (default is 3,5,7, given in the constructor)
	
	float *annulii=0; // 3D matrix of the annulus used for all kinds of photometry, one for each dx/dy shift
	std::vector<int> *annulus_indices=0; // array of length "num_shifts" of index vectors telling what part of each matrix to sum in annulus calculation
	double inner_radius=10; // of the annulus (pixels)
	double outer_radius=0; // of the annulus (pixels)

	float *gaussians=0; // 3D matrix of gaussian weighted apertures for "PSF" photometry, one for each dx/dy shift
	double gauss_sigma=2; // the width of the gaussian (in pixels)
	
	// output arrays are defined here (in C++)
	mwSize output_size[2]={0}; // the same as dim 3 and dim 4 of cutouts
	float **output_raw=0;
	float **output_forced=0;
	float **output_apertures=0;
	float **output_gaussian=0;
	float *best_offset_x=0;
	float *best_offset_y=0;
	const static char data_types[NUM_DATA_TYPES][STRLN]; // this holds strings containing: flux, error, area, background, variance, offset_x, offset_y, width, bad_pixels, flag
	
	float *average_offset_x=0;
	float *average_offset_y=0;
	float *average_width=0;
	
	// function prototypes (implementation at the end)
	Photometry();
	~Photometry();
	void parseInputs(int nrhs, const mxArray *prhs[]);
	mxArray *outputStruct(float **output, int num_fluxes=1); // wrap up the output matrices as a nice matlab style array
	mxArray *outputAverages(); // add a struct with the average offsets and widths
	mxArray *outputMetadataStruct(); // add a struct with some of the parameters and the different aperture masks used
	mxArray *outputArraysStruct(); // add a struct with the actual masks and grid arrays
	mxArray *outputIndicesVectors(std::vector<int> *vectors, int num_radii=1); // produce a cell array with size num_shifts*num_radii (default=1), each with the list of indices for that mask
	
	void makeArrays(); // create all the required memory if it isn't already allocated, make all the required masks
	void makeAllOutputs(); // generate all the output matrices needed
	void allocateOutputArray(float **&output, int num_fluxes=1); // allocate memory for a set of outputs: flux, area, error, background, variance, offset_x/y, width, bad_pixels, flag
	void initializeOutputArray(float **output, int num_fluxes=1); // re-use memory but make sure it is intialized to NaN first
	
	void makeGrids(); // make the X/Y coordinate grid and the dx/dy possible aperture shift matrices
	void makeMasks(); // make a bank of masks to be used for different shifts and types of photometry
	void meshgrid(float *x, float *y, mwSize *dims, int resolution=1);  // fill the two matrices with dimensions "dims" with centered grid points (use resolution>1 to divide each pixel into multiple shifts)
	void makeApertureMasks();
	void makeAnnulusMasks();
	void makeGaussianMasks();
	
	void deleteArrays(); // get rid of all the masks and output arrays (when destroying this object)
	void deleteGrids(); // get rid of the grid matrices
	void deleteOutputs(); // get rid of output arrays only
	void deleteOutputArray(float **&output); // go over and deallocate the memory for one of the outputs
	void deleteMasks(); // go over and deallocate the memory for all the masks
	void deleteApertureMasks();
	void deleteAnnulusMasks();
	void deleteGaussianMasks(); 
	
	void run();
	void run_idx(int start_idx, int end_idx); // use this to run only a subset of the cutouts (for multithreading)
	void calculate(int j); // do the actual work on some cutout array
	void runForced(); // run all cutouts using forced photometry 
	void runForced_idx(int start_idx, int end_idx); // run just a subset of the cutouts (for multithreading)
	void calculateForced(int j); // run a specific cutouts (index j) with the precalculated shift (index idx)
	int getShiftIndex(float x, float y); // find the index closest to the specific shift value x and y in the shift matrices (dx and dy)
	float getError(float reduced_flux, float aperture_variance, float background_variance); // calculate the best estimate for the noise, including background noise, source noise, and scintillation
	bool checkMoments(float offset_x, float offset_y, float width); // returns 1 if there is a problem with the offsets or width

	// make averages over the results
	float getWidthFromMoments(float m2x, float m2y, float mxy); // from the eigenvalues of the 2nd moments
	void calcFrameAverages(float **output, int num_radii=1); // save the average offset_x, offset_y and width for each frame
	// these are obsolete
	float getAverageWidth(float **output); // get the "flux weighted" average width on all non NaN, non flagged cutouts
	float getAverageOffsetX(float **output); // get the "flux weighted" average offset_x on all non NaN, non flagged cutouts
	float getAverageOffsetY(float **output); // get the "flux weighted" average offset_y on all non NaN, non flagged cutouts
	
	// the sum of the product of array1...
	int countNaNs(const float *array); // count the number of NaNs in the array
	float countNaNs(const float *array, const float *array2); // count the number of NaNs weighted by a mask in array2
	float sumArrays(const float *array1);
	float sumArrays(const float *array1, const float *array2);
	float sumArrays(const float *array1, float offset1, const float *array2);
	float sumArrays(const float *array1, const float *array2, const float *array3);
	float sumArrays(const float *array1, float offset1, const float *array2, const float *array3);
	float sumArrays(const float *array1, const float *array2, float offset2, const float *array3, float offset3);	
	float sumArrays(const float *array1, float offset1, const float *array2, float offset2, const float *array3, float offset3);
	float sumArrays(const float *array1, const float *array2, const float *array3, const float *array4);
	float sumArrays(const float *array1, float offset1, const float *array2, float offset2, const float *array3, float offset3, const float *array4);

	int countNonNaNsIndices(const float *array1, const std::vector<int> *vector, int idx); // sum the number of non-NaN values in array1 on the indices in vector[idx]
	float sumIndices(const float *array1, const std::vector<int> *vector, int idx); // sum the values of array1 on the indices in vector[idx]
	float sumIndices(const float *array1, float offset1, const std::vector<int> *vector, int idx); 
	float sumIndices(const float *array1, const float *array2, const std::vector<int> *vector, int idx);
	float sumIndices(const float *array1, float offset1, const float *array2, const std::vector<int> *vector, int idx);
	float sumIndices(const float *array1, float offset1, const float *array2, float offset2, const std::vector<int> *vector, int idx);
	float sumIndices(const float *array1, float offset1, const float *array2, float offset2, const float *array3, float offset3, const std::vector<int> *vector, int idx);
	float medianIndices(const float *array, const std::vector<int> *vector, int idx); // find the median of the array points indicated by vector[idx]
	// float medianIndicesDebug(const float *array, const std::vector<int> *vector, int idx); // find the median of the array points indicated by vector[idx]
	
	// print on screen
	void printMatrix(const int *array, const char *name);
	void printMatrix(const float *array, const char *name);

};

// each output 2D array is defined in this order:
const char Photometry::data_types[NUM_DATA_TYPES][STRLN]={"flux", "area", "error", "background", "variance", "offset_x", "offset_y", "width", "bad_pixels", "flag"};

#define IDX_FLUX 0
#define IDX_AREA 1
#define IDX_ERR 2
#define IDX_BG 3
#define IDX_VAR 4
#define IDX_DX 5
#define IDX_DY 6
#define IDX_WD 7
#define IDX_BAD 8
#define IDX_FLAG 9

#endif

/*
Additional developer notes:
This code has been optimized so it can run live on W-FAST, 
producing photometry live for thousands of stars, on a 100
frames every 4 seconds. 
To that end it uses some nasty programming tricks I will 
try to outline here.

*Preallocating everything in a global object:
In the beginning of the photometry.cpp file there is a declaration
"Photometry photometry;"
This object is allocated and remains in matlab's memory until:
a) The file is compiled again. 
b) Use "clear mex".
c) Matlab exits. 
Therefore all the initializations should happen only once per session. 
These include making the aperture, annulus and gaussian masks, 
the indices lists for the aperture and annulus masks, 
the average arrays and the output arrays. 

*Keeping indices of each mask:
The annulus and aperture masks are logical, 
so we can keep them as a sparse list of 
indices to all the "true" positions. 
These are saved as "aperture_indices" and "annulus_indices". 
When summing over the cutout, we only need to sum the length 
of each such vector, not the size of the entire cutout. 

*Dividing the work to units of single cutouts:
Most of the work done on each cutout is done together. 
With the exception of forced photometry, we run all 
calculations on one cutout before going to the next. 
This allows the CPU to keep in memory the image cutout
we are working on at the moment, and it doesn't need 
to jump around, picking up memory from the entire 
cutouts matrix. 
The forced photometry is done in the same cutout by cutout
way but only after all the other photometry types are done. 
This is because we need to get all the offsets and average 
them before calculating the forced photometry. 

*Multithreading:
Because we handle each cutout independently (with the 
exception of forced photometry), then we can easily split
the work into multiple threads. Each thread gets a distinct
list of cutouts to work on by itself. Since all the threads
need to access existing memory, and do not need to allocate
any memory, there is little overhead to running multiple threads. 

The new computer manages to run 1000 cutouts of 13x13 pixels, 
using 6 cores to do the photometry, at 25 Hz. 

*Using value==value to check if a pixel is NaN:
Turns out that "isnan()" is a really slow function. 
Since every sum we do on the cutouts must check each pixel 
for being NaN (as this is how we mark bad pixels) this test
becomes very expensive. Luckily we can reduce the runtime
dramatically by just comparing array[i]==array[i]. If the 
pixel value is NaN, it will return false even when compared 
to itself. Other values will return true. I haven't tested this
on weird values like Inf, but we don't expect to see those in 
the images. 

*Using the results of one aperture to calculate the next (bigger) one: 
The aperture photometry does concentric apertures with progressively 
larger sizes (wedding cake), that can later be used either to either
choose the best aperture per star or to test if the flux fluctuation 
is real or just width/position related. 
To calculate all these apertures quickly we just re-use the result from 
the previous aperture to calculate the next one, needing only to sum 
the pixels that were not included in any of the former apertures. 


*/