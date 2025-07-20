# Image-Filter-Applicator-FPGA
A hardware-based image filter applicator for the DE1-SoC. It implements the use of VGA, a TRDB-D5M cam, and a coprocessor for image processing.

## Auxiliar Coprocessor.
The auxiliar coprocessor is responsible for matricial operations, it will operate either matrix_a and matrix_b, that are internal registers, or a input matrix. 

### Convolution
The convolution is done in stages, the first stage is responsible for the multiplication of each index of matrix A and B, then the results of that stage are added up in pairs in the subsequent stages so in the end only the final result remains. On the final result, is make sure that is a positive interger on the interval [0,255], if the result is negative, then the absolute value is taken and if its bigger than 255, the result is saturated to 255.

as some operations with kernels needs 2 filters (or 2 matrices) this module processes simultaneously 2 convolutions, and in the end the results are added, so the return of this module is a bus containing the individual results and also its sum, saturated to fit in [0,255]

### Bayer to Greyscale
The camera TRDB-D5M send the image on the bayer format, but the image processing filters used here are supposed to be done on images on greyscale, so this operation takes a partial matrix (from the original image) and convert it to RGB (by taking the mean values) and then converts it to grey (by multiplication by certain weights and adding then up)