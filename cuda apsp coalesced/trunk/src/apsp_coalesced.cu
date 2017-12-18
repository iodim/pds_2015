#include "../include/apsp_coalesced.h"


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

  n = (int) pow(2.0,atoi(argv[1]));
  p = atof(argv[2]);
  w = atoi(argv[3]);
  //t = pow(2,atoi(argv[4]));

  float *W, *W2, *W3, *W4, *Ws;
  float *W1C, *W2C, *W3C, *W4C;
  float *W1L, *W2L, *W3L, *W4L;
  float *WT, *WT2, *WT3, *WT4;

  // Allocate matrix in device memory
  size_t W_size = n*n*sizeof(float);
  float *dev_W;
  dev_W = (float *) malloc(W_size);
  cudaMalloc(&dev_W, W_size);

  // Allocate transposed matrix in device memory
  float *dev_WT;
  dev_WT = (float *) malloc(W_size);
  cudaMalloc(&dev_WT, W_size);

  // Create Adjacency Matrix
  W = makeAdjacency(n,p,w);

  // Copy it a bunch of times.
  W1C = (float *) malloc(W_size);
  W1L = (float *) malloc(W_size);
  W2 = (float *) malloc(W_size);
  W2C = (float *) malloc(W_size);
  W2L = (float *) malloc(W_size);
  W3 = (float *) malloc(W_size);
  W3C = (float *) malloc(W_size);
  W3L = (float *) malloc(W_size);
  W4 = (float *) malloc(W_size);
  W4C = (float *) malloc(W_size);
  W4L = (float *) malloc(W_size);
  Ws = (float *) malloc(W_size);

  memcpy(W1C,W,W_size);
  memcpy(W1L,W,W_size);
  memcpy(W2,W,W_size);
  memcpy(W2C,W,W_size);
  memcpy(W2L,W,W_size);
  memcpy(W3,W,W_size);
  memcpy(W3C,W,W_size);
  memcpy(W3L,W,W_size);
  memcpy(W4,W,W_size);
  memcpy(W4C,W,W_size);
  memcpy(W4L,W,W_size);
  memcpy(Ws,W,W_size);

  // Create transposed matrix W^T
  WT = (float *) malloc(W_size);
  transpose(W,WT,n);

  // Copy it a bunch of times.
  WT2 = (float *) malloc(W_size);
  WT3 = (float *) malloc(W_size);
  WT4 = (float *) malloc(W_size);
  memcpy(WT2,WT,W_size);
  memcpy(WT3,WT,W_size);
  memcpy(WT4,WT,W_size);

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
  // print_2dmatrix(W,n);
  // print_2dmatrix(WT,n);


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
  //print_2dmatrix(W,n);

  //------------------------------------------ Method 1 end.

  // COALESCENT Method 1: One tile per thread, no shared memory.
  //------------------------------------------------------------

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W1C, W_size, cudaMemcpyHostToDevice);
  cudaMemcpy(dev_WT, WT, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    //printf("%d\n",k );
    CFW_single_tile_no_shared<<<dimGrid, dimBlock>>>(dev_W, dev_WT, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W1C, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nCOALESCENT Method 1: One tile per thread, no shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,gridSide);
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W1C,n);

  //------------------------------------------ COALESCENT Method 1 end.


  // SINGLE_ROW_COALESCENCE Method 1: One tile per thread, no shared memory.
  //------------------------------------------------------------------------

  // Calculate Grid and Block dimensions.
  int gridSide_x = n/256 + 1;
  int gridSide_y = n;
  dim3 dimGrid_L(gridSide_x,gridSide_y);

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W1L, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_single_tile_no_shared<<<dimGrid_L, 256>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W1L, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nSINGLE_ROW_COALESCENCE Method 1: One tile per thread, no shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide_x,gridSide_y);
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W1L,n);

  //------------------------------------------ SINGLE_ROW_COALESCENCE Method 1 end.


  // Method 2: One tile per thread, using shared memory.
  //-------------------------------------------------

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W2, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_single_tile_shared<<<dimGrid,dimBlock>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W2, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);
  printf("\nMethod 2: One tile per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,gridSide);
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W2,n);

  //------------------------------------------ Method 2 end.


  // COALESCENT Method 2: One tile per thread, using shared memory.
  //---------------------------------------------------------------

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W2C, W_size, cudaMemcpyHostToDevice);
  cudaMemcpy(dev_WT, WT2, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    CFW_single_tile_shared<<<dimGrid,dimBlock>>>(dev_W, dev_WT, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W2C, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);
  printf("\nCOALESCENT Method 2: One tile per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,gridSide);
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W2C,n);

  //------------------------------------------ COALESCENT Method 2 end.

  // SINGLE_ROW_COALESCENCE Method 2: One tile per thread, using shared memory.
  //-------------------------------------------------

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W2L, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_single_tile_shared<<<dimGrid_L,256>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W2L, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);
  printf("\nSINGLE_ROW_COALESCENCE Method 2: One tile per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide_x,gridSide_y);
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W2L,n);

  //------------------------------------------ SINGLE_ROW_COALESCENCE Method 2 end.



  // Method 3: Two tiles per thread, using shared memory.
  //-------------------------------------------------

  // Calculate Grid dimensions.
  dim3 dimGrid_3(gridSide,max(gridSide/2, 1));

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W3, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_two_tiles_shared<<<dimGrid_3,dimBlock>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W3, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nMethod 3: Two tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,max(gridSide/2, 1));
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W3,n);

  //------------------------------------------ Method 3 end.


  // COALESCENT Method 3: Two tiles per thread, using shared memory.
  //----------------------------------------------------------------

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W3C, W_size, cudaMemcpyHostToDevice);
  cudaMemcpy(dev_WT, WT3, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_two_tiles_shared<<<dimGrid_3,dimBlock>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W3C, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nCOALESCENT Method 3: Two tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,max(gridSide/2, 1));
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W3C,n);

  //------------------------------------------ COALESCENT Method 3 end.



  // SINGLE_ROW_COALESCENCE Method 3: Two tiles per thread, using shared memory.
  //----------------------------------------------------------------------------

  // Calculate Grid dimensions.
  dim3 dimGrid_3L(gridSide_x,gridSide_y/2);

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W3L, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_two_tiles_shared<<<dimGrid_3L,256>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W3L, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nSINGLE_ROW_COALESCENCE Method 3: Two tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide_x,gridSide_y/2);
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W3L,n);

  //------------------------------------------ SINGLE_ROW_COALESCENCE Method 3 end.



  // Method 4: Four tiles per thread, using shared memory.
  //-------------------------------------------------

  // Calculate Grid and Block dimensions.
  dim3 dimGrid_4(gridSide,max(gridSide/4, 1));


  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W4, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_four_tiles_shared<<<dimGrid_4,dimBlock>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W4, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nMethod 4: Four tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,max(gridSide/4, 1));
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W4,n);

  //------------------------------------------ Method 4 end.

  // COALESCENT Method 4: Four tiles per thread, using shared memory.
  //-----------------------------------------------------------------

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W4C, W_size, cudaMemcpyHostToDevice);
  cudaMemcpy(dev_WT, WT4, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    FW_four_tiles_shared<<<dimGrid_4,dimBlock>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W4C, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nCOALESCENT Method 4: Four tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide,max(gridSide/4, 1));
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W4C,n);

  //------------------------------------------ COALESCENT Method 4 end.


  // SINGLE_ROW_COALESCENCE Method 4: Four tiles per thread, using shared memory.
  //-----------------------------------------------------------------------------

  // Calculate Grid dimensions.
  dim3 dimGrid_4L(gridSide_x,gridSide_y/4);

  gettimeofday (&startwtime, NULL);

  // Copy matrix from host memory to device memory
  cudaMemcpy(dev_W, W4L, W_size, cudaMemcpyHostToDevice);

  // Invoke kernel
  for(int k=0;k<n;k++) {
    LFW_four_tiles_shared<<<dimGrid_4L,256>>>(dev_W, n, k);
    cudaThreadSynchronize();
  }

  // Copy matrix back to host memory.
  cudaMemcpy(W4L, dev_W, W_size, cudaMemcpyDeviceToHost);

  gettimeofday (&endwtime, NULL);

  seq_time = (double)((endwtime.tv_usec - startwtime.tv_usec)/1.0e6
            + endwtime.tv_sec - startwtime.tv_sec);

  printf("\nSINGLE_ROW_COALESCENCE Method 4: Four tiles per thread, using shared memory:\n  Grid_x: %d\n  Grid_y: %d",gridSide_x,gridSide_y/4);
  printf("\n  Clock time = %f\n", seq_time);
  //print_2dmatrix(W4L,n);

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



  // Check if parallel methods work correctly.
  int all_correct = 0;

  fflush( stdout );
  if(!memcmp(Ws, W, n*n*sizeof(float))) {
    printf("\n\nMethod 1 works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W1C, n*n*sizeof(float))) {
    printf("\nMethod 1 COALESCENT works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W1L, n*n*sizeof(float))) {
    printf("\nMethod 1 SINGLE_ROW_COALESCENCE works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W2, n*n*sizeof(float))) {
    printf("\n\nMethod 2 works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W2C, n*n*sizeof(float))) {
    printf("\nMethod 2 COALESCENT works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W2L, n*n*sizeof(float))) {
    printf("\nMethod 2 SINGLE_ROW_COALESCENCE works fine.");
    all_correct++;
  }
   if(!memcmp(Ws, W3, n*n*sizeof(float))) {
    printf("\n\nMethod 3 works fine.");
    all_correct++;
  }
   if(!memcmp(Ws, W3C, n*n*sizeof(float))) {
    printf("\nMethod 3 COALESCENT works fine.");
    all_correct++;
  }
   if(!memcmp(Ws, W3L, n*n*sizeof(float))) {
    printf("\nMethod 3 SINGLE_ROW_COALESCENCE works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W4, n*n*sizeof(float))) {
    printf("\n\nMethod 4 works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W4C, n*n*sizeof(float))) {
    printf("\nMethod 4 COALESCENT works fine.");
    all_correct++;
  }
  if(!memcmp(Ws, W4L, n*n*sizeof(float))) {
    printf("\nMethod 4 SINGLE_ROW_COALESCENCE works fine.");
    all_correct++;
  }

  if(all_correct==12)
    printf("\n\nAll methods work correctly.\n");


  // Free allocated memory.
  free(W);
  free(W1C);
  free(W1L);
  free(W2);
  free(W2C);
  free(W2L);
  free(W3);
  free(W3C);
  free(W3L);
  free(W4);
  free(W4C);
  free(W4L);
  free(Ws);
  free(WT);
  free(WT2);
  free(WT3);
  free(WT4);
  cudaFree(dev_W);
  cudaFree(dev_WT);

  return 0;
}
