#include "../include/apsp.h"

float inf=1.0/0.0;


float rand_factor();
void print_2dmatrix(float *W, int n);
float* makeAdjacency(int n, float p, int w);
void Floyd_Warshall(float *W, int n);

// Kernel functions
__global__ void FW_single_tile_no_shared(float *W, int n, int k);
__global__ void FW_single_tile_shared(float *W, int n, int k);
__global__ void FW_two_tiles_shared(float *W, int n, int k);
__global__ void FW_four_tiles_shared(float *W, int n, int k);




int main(int argc, char **argv) {

int n,w;
//int t;
float p;
struct timeval startwtime, endwtime;
double seq_time;


if (argc != 4) {
  printf("Usage: %s n p w\n"
         " where\n"
         " 2^n  : size of the sides of the matrix \n"
         " p    : probability that 2 vertices are directly connected\n"
         " w    : maximum value of edge weights\n\n"
         //" 2^t  : number of tiles per thread for the 3rd method\n"
  , argv[0]);

  return (1);
}

n = pow(2,atoi(argv[1]));
p = atof(argv[2]);
w = atoi(argv[3]);
//t = pow(2,atoi(argv[4]));


float *W, *W2, *W3, *W4, *Ws;


// Allocate matrix in device memory
size_t W_size = n*n*sizeof(float);
float *dev_W;
dev_W = (float *) malloc(W_size);
cudaMalloc(&dev_W, W_size);

// Create Adjacency Matrix
W = makeAdjacency(n,p,w);

// Copy it a bunch of times.
W2 = (float *) malloc(W_size);
W3 = (float *) malloc(W_size);
W4 = (float *) malloc(W_size);
Ws = (float *) malloc(W_size);
memcpy(W2,W,W_size);
memcpy(W3,W,W_size);
memcpy(W4,W,W_size);
memcpy(Ws,W,W_size);


// Display system information
int nDevices;
cudaGetDeviceCount(&nDevices);
printf("\n\n");
for (int i = 0; i < nDevices; i++) {
  cudaDeviceProp prop;
  cudaGetDeviceProperties(&prop, i);
  printf("Device Number: %d\n", i);
  printf("  Device name: %s\n", prop.name);
  printf("  Max threads per block: %d\n", prop.maxThreadsPerBlock);
}


// Calculate general Problem Size
int size = n*n;
printf("\nSize of problem: %d\n\n",size);

// Print Adjacency Matrix
//print_2dmatrix(W,n);




// Method 1: One tile per thread, no shared memory.
//-------------------------------------------------

// Calculate Grid and Block dimensions.
int gridSide = n/16;
if(n%16)
  gridSide++;
dim3 dimGrid(gridSide,gridSide);
dim3 dimBlock(16,16);


gettimeofday (&startwtime, NULL);

// Copy matrix from host memory to device memory
cudaMemcpy(dev_W, W, W_size, cudaMemcpyHostToDevice);

// Invoke kernel
for(int k=0;k<n;k++) {
  FW_single_tile_no_shared<<<dimGrid, dimBlock>>>(dev_W, n, k);
  cudaThreadSynchronize();
}

// Copy matrix back to host memory.
cudaMemcpy(W, dev_W, W_size, cudaMemcpyDeviceToHost);

gettimeofday (&endwtime, NULL);

seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
          + endwtime.tv_sec - startwtime.tv_sec);

printf("\nMethod 1: One tile per thread, no shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,gridSide);
printf("\n  Clock time = %f\n", seq_time);
// print_2dmatrix(W,n);

//------------------------------------------ Method 1 end.




// Method 2: One tile per thread, using shared memory.
//-------------------------------------------------

// Calculate Grid dimensions.
int gridSide_x = max(n/256, 1);
int gridSide_y = n;

dim3 dimGrid_2(gridSide_x,gridSide_y);

gettimeofday (&startwtime, NULL);

// Copy matrix from host memory to device memory
cudaMemcpy(dev_W, W2, W_size, cudaMemcpyHostToDevice);

// Invoke kernel
for(int k=0;k<n;k++) {
  FW_single_tile_shared<<<dimGrid_2,256>>>(dev_W, n, k);
  cudaThreadSynchronize();
}

// Copy matrix back to host memory.
cudaMemcpy(W2, dev_W, W_size, cudaMemcpyDeviceToHost);

gettimeofday (&endwtime, NULL);

seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
          + endwtime.tv_sec - startwtime.tv_sec);
printf("\nMethod 2: One tile per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide_x,gridSide_y);
printf("\n  Clock time = %f\n", seq_time);
// print_2dmatrix(W2,n);

//------------------------------------------ Method 2 end.



// Method 3: Two tiles per thread, using shared memory.
//-------------------------------------------------

// Calculate Grid dimensions.
dim3 dimGrid_3(gridSide_x,gridSide_y/2);

gettimeofday (&startwtime, NULL);

// Copy matrix from host memory to device memory
cudaMemcpy(dev_W, W3, W_size, cudaMemcpyHostToDevice);

// Invoke kernel
for(int k=0;k<n;k++) {
  FW_two_tiles_shared<<<dimGrid_3,256>>>(dev_W, n, k);
  cudaThreadSynchronize();
}

// Copy matrix back to host memory.
cudaMemcpy(W3, dev_W, W_size, cudaMemcpyDeviceToHost);

gettimeofday (&endwtime, NULL);

seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
          + endwtime.tv_sec - startwtime.tv_sec);

printf("\nMethod 3: Two tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide_x,gridSide_y/2);
printf("\n  Clock time = %f\n", seq_time);
//print_2dmatrix(W3,n);

//------------------------------------------ Method 3 end.


// Method 4: Four tiles per thread, using shared memory.
//-------------------------------------------------

// Calculate Grid dimensions.
dim3 dimGrid_4(gridSide_x,gridSide_y/4);

gettimeofday (&startwtime, NULL);

// Copy matrix from host memory to device memory
cudaMemcpy(dev_W, W4, W_size, cudaMemcpyHostToDevice);

// Invoke kernel
for(int k=0;k<n;k++) {
  FW_four_tiles_shared<<<dimGrid_4,256>>>(dev_W, n, k);
  cudaThreadSynchronize();
}

// Copy matrix back to host memory.
cudaMemcpy(W4, dev_W, W_size, cudaMemcpyDeviceToHost);

gettimeofday (&endwtime, NULL);

seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
          + endwtime.tv_sec - startwtime.tv_sec);

printf("\nMethod 4: Four tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide_x,gridSide_y/4);
printf("\n  Clock time = %f\n", seq_time);
//print_2dmatrix(W4,n);

//------------------------------------------ Method 4 end.



// Serial Implementation
//-------------------------------------------------

gettimeofday (&startwtime, NULL);
Floyd_Warshall(Ws,n);
gettimeofday (&endwtime, NULL);

seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
		      + endwtime.tv_sec - startwtime.tv_sec);

printf("\n\nSerial implementation clock time = %f\n", seq_time);

//------------------------------------------ Serial end.



// Check of parallel methods work correctly.
int all_correct = 0;

fflush( stdout );
if(!memcmp(Ws, W, n*n*sizeof(float))) {
  printf("\n\nMethod 1 works fine.");
  all_correct++;
}
if(!memcmp(Ws, W2, n*n*sizeof(float))) {
  printf("\nMethod 2 works fine.");
  all_correct++;
}
 if(!memcmp(Ws, W3, n*n*sizeof(float))) {
  printf("\nMethod 3 works fine.");
  all_correct++;
}
if(!memcmp(Ws, W4, n*n*sizeof(float))) {
  printf("\nMethod 4 works fine.");
  all_correct++;
}

if(all_correct==4)
  printf("\n\nAll methods work correctly.\n");


// Free allocated memory.
free(W);
free(W2);
free(W3);
free(W4);
free(Ws);
cudaFree(dev_W);

return 0;
}





// Create Adjacency matrix, based on the matlab code given.
float* makeAdjacency(int n, float p, int w)
{
  int i,j;
  float* A;

  srand(time(NULL));
  A = (float *) malloc(n*n*sizeof(float));

  for(i=0;i<n;i++) {
    for(j=0;j<n;j++)
      if(rand_factor() > p)  A[i*n+j] = inf;
      else  A[i*n+j] = rand_factor()*w;
    A[i*n+i] = 0;
  }

  return A;

}


// Returns random number from 0 to 1.
float rand_factor()
{
    return (float)rand() / (float)RAND_MAX ;
}


// Prints a 2d matrix.
void print_2dmatrix(float *W, int n)
{
  int i,j;
  printf("\n\n");
  for(i=0;i<n;i++)
    for(j=0;j<n;j++) {
      printf("%-9f  ",W[i*n+j]);
      if(j==n-1) printf("\n");
    }

}


// Serial Floyd Warshall implementation.
void Floyd_Warshall(float *W, int n)
{
  int i,j,k;
  for(k=0;k<n;k++)
    for(i=0;i<n;i++)
      for(j=0;j<n;j++)
        if(W[i*n+j] > W[i*n+k] + W[k*n+j])
          W[i*n+j] = W[i*n+k] + W[k*n+j];
}


// Parallel method 1: Single tile per thread, without shared memory.
__global__ void FW_single_tile_no_shared(float *W, int n, int k)
{

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;


  float row_k = W[n*row+k];
  float k_col = W[k*n+col];
  __syncthreads();  // Does not seem to be necessary, code apparently works fine without it.(****)

  if(W[n*row+col] > row_k + k_col)
    W[n*row+col] = row_k + k_col;
}


// Parallel method 2: Single tile per thread, shared memory.
__global__ void FW_single_tile_shared(float *W, int n, int k)
{

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y;
  if(col >= n)
    return;

  __shared__  float row_k;
  if(threadIdx.x==0) row_k = W[n*row+k];
  float k_col = W[k*n+col];
 __syncthreads();

  if(W[n*row+col] > row_k + k_col)
    W[n*row+col] = row_k + k_col;
}


// Parallel method 3: Two tiles per thread, shared memory.
__global__ void FW_two_tiles_shared(float *W, int n, int k)
{

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k;
  __shared__ float row_k1;
  if(threadIdx.x==0) {
    row_k = W[n*row+k];
    row_k1 = W[n*row+k+n*gridDim.y];
  }
  float k_col = W[k*n+col];
 __syncthreads();

  float alternative = row_k + k_col;
  float alternative1 = row_k1 + k_col;

  if(W[n*row+col] > alternative)
    W[n*row+col] = alternative;
  if(W[n*row+col+n*gridDim.y] > alternative1)
    W[n*row+col+n*gridDim.y] = alternative1;
}



// Parallel method 4: Four tiles per thread, shared memory.
__global__ void FW_four_tiles_shared(float *W, int n, int k)
{

  int i;
  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k[4];
  if(threadIdx.x==0) {
    for(i=0; i<4; i++)
      row_k[i] = W[n*row+k+n*gridDim.y*i];
  }
  float k_col = W[k*n+col];
 __syncthreads();

  for(i=0; i<4; i++)
    if(W[n*row+col+n*gridDim.y*i] > row_k[i] + k_col)
        W[n*row+col+n*gridDim.y*i] = row_k[i] + k_col;
}
