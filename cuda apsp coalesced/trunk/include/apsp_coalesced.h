#ifndef APSP_COALESCED_H
#define APSP_COALESCED_H

#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <math.h>

float inf=1.0/0.0;

// Helper functions
float rand_factor();
void print_2dmatrix(float *W, int n);
void transpose(float *W, float *WT, int n);
float* makeAdjacency(int n, float p, int w);
void Floyd_Warshall(float *W, int n);

// Kernel functions
__global__ void FW_single_tile_no_shared(float *W, int n, int k);
__global__ void CFW_single_tile_no_shared(float *W, float *WT, int n, int k);
__global__ void LFW_single_tile_no_shared(float *W, int n, int k);

__global__ void FW_single_tile_shared(float *W, int n, int k);
__global__ void CFW_single_tile_shared(float *W, float *WT, int n, int k);
__global__ void LFW_single_tile_shared(float *W, int n, int k);

__global__ void FW_two_tiles_shared(float *W, int n, int k);
__global__ void CFW_two_tile_shared(float *W, float *WT, int n, int k);
__global__ void LFW_two_tiles_shared(float *W, int n, int k);

__global__ void FW_four_tiles_shared(float *W, int n, int k);
__global__ void CFW_four_tiles_shared(float *W, float *WT, int n, int k);
__global__ void LFW_four_tiles_shared(float *W, int n, int k);


// Create Adjacency matrix, based on the matlab code given.
float* makeAdjacency(int n, float p, int w) {
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
float rand_factor() {
    return (float)rand() / (float)RAND_MAX ;
}

// Prints a 2d matrix.
void print_2dmatrix(float *W, int n) {
  int i,j;
  printf("\n\n");
  for(i=0;i<n;i++)
    for(j=0;j<n;j++) {
      printf("%-9f  ",W[i*n+j]);
      if(j==n-1) printf("\n");
    }

}

// Creates a transposed copy of input matrix.
void transpose(float *W, float *WT, int n) {
    int i,j;
    for(i=0;i<n;i++)
      for(j=0;j<n;j++)
        WT[i*n+j] = W[j*n+i];
}


// Serial Floyd Warshall implementation.
void Floyd_Warshall(float *W, int n) {
  int i,j,k;
  for(k=0;k<n;k++)
    for(i=0;i<n;i++)
      for(j=0;j<n;j++)
        if(W[i*n+j] > W[i*n+k] + W[k*n+j])
          W[i*n+j] = W[i*n+k] + W[k*n+j];
}


// Parallel method 1: Single tile per thread, without shared memory.
__global__ void FW_single_tile_no_shared(float *W, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  float row_k = W[n*row+k];
  float k_col = W[k*n+col];
  __syncthreads();

  float alternative = row_k + k_col;

  if(W[n*row+col] > alternative)
    W[n*row+col] = alternative;
}

// COALESCENT Parallel method 1: Single tile per thread, without shared memory.
__global__ void CFW_single_tile_no_shared(float *W, float *WT, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  float row_k = WT[k*n+row];
  float k_col = W[k*n+col];
  __syncthreads();

  float alternative = row_k + k_col;

  if(W[n*row+col] > alternative) {
    W[n*row+col] = alternative;
    WT[n*col+row] = alternative;
  }
}


// Parallel method 2: Single tile per thread, shared memory.
__global__ void FW_single_tile_shared(float *W, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k[16];
  if(threadIdx.x==0)
      row_k[threadIdx.y] = W[n*row+k];

  float k_col = W[k*n+col];
 __syncthreads();

  if(W[n*row+col] > row_k[threadIdx.y] + k_col)
    W[n*row+col] = row_k[threadIdx.y] + k_col;
}


// COALESCENT Parallel method 2: Single tile per thread, shared memory.
__global__ void CFW_single_tile_shared(float *W, float *WT, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k[16];
  if(threadIdx.x==0)
      row_k[threadIdx.y] = WT[k*n+row];

  float k_col = W[k*n+col];
  __syncthreads();

  if(W[n*row+col] > row_k[threadIdx.y] + k_col) {
    W[n*row+col] = row_k[threadIdx.y] + k_col;
    WT[n*col+row] = row_k[threadIdx.y] + k_col;
  }
}

// Parallel method 3: Two tiles per thread, shared memory.
__global__ void FW_two_tiles_shared(float *W, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k[16];
  __shared__ float row_k1[16];
  if(threadIdx.x==0) {
    row_k[threadIdx.y] = W[n*row+k];
    row_k1[threadIdx.y] = W[n*row+k+n*gridDim.y*blockDim.y];
  }
  float k_col = W[k*n+col];
  __syncthreads();

  if(W[n*row+col] > row_k[threadIdx.y] + k_col)
    W[n*row+col] = row_k[threadIdx.y] + k_col;

  if(W[n*row+col+n*gridDim.y*blockDim.y] > row_k1[threadIdx.y] + k_col)
    W[n*row+col+n*gridDim.y*blockDim.y] = row_k1[threadIdx.y] + k_col;

}

// COALESCENT Parallel method 3: Two tiles per thread, shared memory.
__global__ void CFW_two_tiles_shared(float *W, float *WT, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k[16];
  __shared__ float row_k1[16];
  if(threadIdx.x==0) {
      row_k[threadIdx.y] = WT[n*k+row];
      row_k1[threadIdx.y] = WT[n*k+row+n*gridDim.x*blockDim.x];
  }
  float k_col = W[k*n+col];
  __syncthreads();

  if(W[n*row+col] > row_k[threadIdx.y] + k_col) {
    W[n*row+col] = row_k[threadIdx.y] + k_col;
    WT[n*col+row] = row_k[threadIdx.y] + k_col;
  }

  if(W[n*row+col+n*gridDim.y*blockDim.y] > row_k1[threadIdx.y] + k_col) {
    W[n*row+col+n*gridDim.y*blockDim.y] = row_k1[threadIdx.y] + k_col;
    WT[n*col+row+n*gridDim.x*blockDim.y] = row_k1[threadIdx.y] + k_col;
  }

}

// Parallel method 4: Four tiles per thread, shared memory.
__global__ void FW_four_tiles_shared(float *W, int n, int k) {

  int i;
  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k[64];
  if(threadIdx.x==0)
    for(i=0; i<4; i++)
      row_k[threadIdx.y+blockDim.x*i] = W[n*row+k+n*gridDim.y*blockDim.y*i];

  float k_col = W[k*n+col];
  __syncthreads();

  for(i=0; i<4; i++)
    if(W[n*row+col+n*gridDim.y*blockDim.y*i] > row_k[threadIdx.y+blockDim.x*i] + k_col)
      W[n*row+col+n*gridDim.y*blockDim.y*i] = row_k[threadIdx.y+blockDim.x*i] + k_col;

}


// COALESCCENT Parallel method 4: Four tiles per thread, shared memory.
__global__ void CFW_four_tiles_shared(float *W, float *WT, int n, int k) {

  int i;
  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y * blockDim.y + threadIdx.y;
  if(col >= n)
    return;

  __shared__ float row_k[64];
  if(threadIdx.x==0)
    for(i=0; i<4; i++)
      row_k[threadIdx.y+blockDim.x*i] = WT[n*k+row+n*gridDim.x*blockDim.x*i];

  float k_col = W[k*n+col];
  __syncthreads();

  for(i=0; i<4; i++)
    if(W[n*row+col+n*gridDim.y*blockDim.x*i] > row_k[threadIdx.y+blockDim.x*i] + k_col) {
      W[n*row+col+n*gridDim.y*blockDim.x*i] = row_k[threadIdx.y+blockDim.x*i] + k_col;
      WT[n*col+row+n*gridDim.x*blockDim.x*i] = row_k[threadIdx.y+blockDim.x*i] + k_col;
    }
}


// SINGLE ROW Parallel method 1: Single tile per thread, without shared memory.
__global__ void LFW_single_tile_no_shared(float *W, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y;
  if(col >= n)
    return;

  float row_k = W[n*row+k];
  float k_col = W[k*n+col];
  __syncthreads();  // Does not seem to be necessary, code apparently works fine without it.(****)

  float alternative = row_k + k_col;

  if(W[n*row+col] > alternative)
    W[n*row+col] = alternative;
}


// SINGLE ROW Parallel method 2: Single tile per thread, shared memory.
__global__ void LFW_single_tile_shared(float *W, int n, int k) {

  int col = blockIdx.x * blockDim.x + threadIdx.x;
  int row = blockIdx.y;
  if(col >= n)
    return;

  __shared__  float trkc;
  if(threadIdx.x==0) trkc = W[n*row+k];
  float tckr = W[k*n+col];
  __syncthreads();

  if(W[n*row+col] > trkc + tckr)
    W[n*row+col] = trkc + tckr;
}


// SINGLE ROW Parallel method 3: Two tiles per thread, shared memory.
__global__ void LFW_two_tiles_shared(float *W, int n, int k) {

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



// SINGLE ROW Parallel method 4: Four tiles per thread, shared memory.
__global__ void LFW_four_tiles_shared(float *W, int n, int k) {

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

#endif
