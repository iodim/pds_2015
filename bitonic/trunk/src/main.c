/*
 main.c

 Benchmark and driver program for bitonic_serial, bitonic_pthread, etc.
*/

#include "../include/main.h"
#include "../include/global_vars.h"
#include "../include/bitonic_serial.h"
#include "../include/bitonic_pthread.h"
#include "../include/bitonic_openmp.h"
#include "../include/bitonic_cilk.h"

int N;
int P;
int *a;
int BASECASE;

int main(int argc, char **argv) {

    int EXIT_STATUS = EXIT_SUCCESS;

    if (argc == 3) {
        N = 1 << atoi(argv[1]);
        P = 1 << atoi(argv[2]);
        a = (int *) malloc(N * sizeof(int));
        BASECASE = N/P;

        /*
        Benching imperative bitonic sort
        */
        init();
        gettimeofday(&startwtime, NULL);
        impBitonicSort();
        gettimeofday(&endwtime, NULL);
        seq_time = (double) ((endwtime.tv_usec - startwtime.tv_usec) / 1.0e6
                             + endwtime.tv_sec - startwtime.tv_sec);
        printf("Imperative wall clock time = %f\n", seq_time);
        EXIT_STATUS |= test();

        /*
        Benching recursive bitonic sort
        */
        init();
        gettimeofday(&startwtime, NULL);
        sort();
        gettimeofday(&endwtime, NULL);
        seq_time = (double) ((endwtime.tv_usec - startwtime.tv_usec) / 1.0e6
                             + endwtime.tv_sec - startwtime.tv_sec);
        printf("Recursive wall clock time = %f\n", seq_time);
        EXIT_STATUS |= test();

        /*
        Benching stdlib::quicksort
        */
        init();
        gettimeofday(&startwtime, NULL);
        qsort(a, N, sizeof(int), cmp);
        gettimeofday(&endwtime, NULL);
        seq_time = (double) ((endwtime.tv_usec - startwtime.tv_usec) / 1.0e6
                             + endwtime.tv_sec - startwtime.tv_sec);
        printf("stdlib::qsort wall clock time = %f\n", seq_time);
        EXIT_STATUS |= test();

        /*
        Benching pthread ecursive bitonic sort
        */
        init();
        gettimeofday(&startwtime, NULL);
        pthread_sort();
        gettimeofday(&endwtime, NULL);
        seq_time = (double) ((endwtime.tv_usec - startwtime.tv_usec) / 1.0e6
                             + endwtime.tv_sec - startwtime.tv_sec);
        printf("Pthread wall clock time = %f\n", seq_time);
        EXIT_STATUS |= test();

        /*
        Benching openmp imperative bitonic sort
        */
        init();
        gettimeofday(&startwtime, NULL);
        openmp_sort();
        gettimeofday(&endwtime, NULL);
        seq_time = (double) ((endwtime.tv_usec - startwtime.tv_usec) / 1.0e6
                             + endwtime.tv_sec - startwtime.tv_sec);
        printf("OpenMP wall clock time = %f\n", seq_time);
        EXIT_STATUS |= test();

        /*
        Benching cilk imperative bitonic sort
        */
        init();
        gettimeofday(&startwtime, NULL);
        cilk_sort();
        gettimeofday(&endwtime, NULL);
        seq_time = (double) ((endwtime.tv_usec - startwtime.tv_usec) / 1.0e6
                             + endwtime.tv_sec - startwtime.tv_sec);
        printf("Cilk wall clock time = %f\n", seq_time);
        EXIT_STATUS |= test();


        return EXIT_STATUS;
    } else {
        printf("Usage: %s q p\n  where n=2^q is problem size (power of two) "
         "with the use of 2^p threads\n",
               argv[0]);
        exit(1);
    }


}

/** -------------- SUB-PROCEDURES  ----------------- **/

/** procedure test() : verify sort results **/
int test() {
    int pass = 1;
    int i;
    for (i = 1; i < N; i++) {
        pass &= (a[i - 1] <= a[i]);
    }

    // printf(" TEST %s\n", (pass) ? "PASSed" : "FAILed");
    return !pass;
}


/** procedure init() : initialize array "a" with data **/
void init() {
    int i;
    for (i = 0; i < N; i++) {
        a[i] = rand() % N; // (N - i);
    }
}

/** procedure  print() : print array elements **/
void print() {
    int i;
    for (i = 0; i < N; i++) {
        printf("%d\n", a[i]);
    }
    printf("\n");
}

static inline int cmp(const void *p, const void *q){
       return ( *(int*)p - *(int*)q );
}
