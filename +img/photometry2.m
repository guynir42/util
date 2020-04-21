% Usage: [outputs, arrays] = photometry2(cutouts, varargin)
% Calculate all sorts of photometric measurements on image cutouts. 
%
% By default, this calculates raw photometry (sum of the entire square), 
% aperture photometry on a few radii, forced photometry (on the largest
% radius using the average position of all stars), and gaussian PSF
% photometry, assuming some gaussian width. 
% 
% Input: a matrix of cutouts, must be single precision, 2-4 dimensional. 
%        The 3rd dimension is the frame number, while the 4th dimension is
%        the cutout/star number. It is better to use 1st and 2nd dimensions
%        that are of equal size with an odd number of pixels. 
%
% Output: Each type of photometry products are returned in a separate
%         struct, where each field contains a matrix of results for each
%         star and each cutout. 
%         The different products are:
%           *flux: not background subtracted! (see "background" below)
%           *area: how many pixels in the aperture/PSF, removing bad pixels
%           *error: estimate of the photometric error per sample. 
%           *background: per pixel, to subtract do flux-area*background. 
%           *variance: per pixel, measured from the background annulus. 
%           *offset_x/y: in pixels, relative to the center of the cutout. 
%           *width: average 2nd moment of the PSF, equivalent to gaussian
%                   "sigma" width parameter. 
%           *bad_pixels: that are inside the effective aperture
%                        (for gaussian, it is the weighted sum).
%           *flag: set to 1 if there is a problem with the centroids 
%                  (e.g., negative width, very large offsets). 
%
%         In addition to the different photometry types we also get a
%         structure with the input parameters (aperture radii etc). 
%         It is useful to keep a copy of this structure for later reference
%         when you want to document your results. 
%         Also get a structure with the frame average offsets and widths. 
%
%         An optional second argument is a structure containing the arrays
%         and index vectors used for the photometery. This is useful mostly
%         for debugging purposes. 
%         
%
% Optional Arguments:
%       *index: choose which photometry object to use. There are several
%               (usually 10) objects saved on global scope. When you want
%               to run this code with different parameters or input sizes,
%               it would save you some time allocating the output arrays if
%               you keep each calculation on a different object. 
%       *aperture or radius: a vector of aperture radii to be used for
%                            aperture photometry (in pixels!). The biggest 
%                            radius is also used for recentering (see
%                            below) and for forced photometry. 
%                            Default is [5,7,9].
%       *gauss_sigma: the width of the gaussian used in PSF photometery.
%                     Default is 2 pixels. 
%       *annulus: a one or two element vector for the inner and outer
%                 radius of the background annulus. If second element is
%                 not given or is smaller than the first, assume it is
%                 infinite (so all pixels above the first radius are used).
%                 Default is 10 (inner) and 0 (outer, equvalent to Inf). 
%       *gain: This is used only to estimate the errors from source noise.
%              Default is 1. 
%       *scintillation_fraction: Used to estimate the additional noise
%                                caused by intensity scintillation. This
%                                also only affects error estimates. 
%                                Default is 0.
%       *resolution: How many shifts are needed for all the different
%                    apertures/annuli/PSFs. When resolution is 1 (default)
%                    the different masks are moved in steps of single
%                    pixels, and if resolution is bigger than 1, use more
%                    steps inside each pixel for the relative shifts of the
%                    masks. The default is 1 but 2 is also a good choice,
%                    and I don't think we need more than that.
%                    Use only integer values. 
%       *threads: how many physical cores should be used to split the work 
%                 on different cutouts. For serious computers we should see
%                 a speedup proportional to the number of threads for at
%                 least threads<5. Default is 1 (no multithreading). 
%       *iterations: How many repositions of the gaussians are used on each
%                    cutout before settling on the results. Default: 2.
%       *use_centering_aperture: If true, use a an aperture at the position
%                                from the raw photometery, just to get a
%                                little better positioning before going on
%                                to the more narrow gaussian photometry. 
%       *use_gaussian: If falue, skip gaussians altogether (default true).
%       *use_apertures: If false, skip aperture photometery (default true).
%       *use_forced: If false, skip doing forced photometry (default true). 
%       *use_median: If true, use median value of annulus pixels to calculate
%                    the background (instead of mean). Default true. 
%       *debug_bit: Level of verbosity of the code (default: 0). 
%       
%
%
% The position of the offsets of each star in its cutout is calculated by
% first taking the centroids of the background subtracted sum on the whole
% square (raw-photometry). 
% If use_centering=1 then an aperture is moved onto the offset position and
% used to produce new centroids. 
% If use_gaussian=1 then PSF photometry is performed iteratively, each time
% improving the centroid positions. 
% Those positions are used to place a few concentric apertures, calculating
% the photometry in that position for each radius. 
% Finally, the flux-averaged offsets are calculated from the best position
% estimate (which is chosen to be gaussian, aperture or raw, in decending
% order of accuracy), and used to do forced photometry on all cutouts with
% the largest aperture placed at the average offsets. 
% In all cases the background is estimated from an annulus centered around 
% at the position of the PSF/aperture. For raw-photometry it is centered
% around the middle of the cutout.  
%
% To compile this function just do "mex photometry.cpp" (no prerequisits). 
% Make sure you do this inside the correct directory (+util/+img). 
%
% Additional developer notes about the nitty gritty can be found at the end
% of the header file photometry2.h. 
%
