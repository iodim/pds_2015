/*
 bitonic_pthread.c

 Implements bitonic sort with the use of the pthreads library.
*/

#include "../include/global_vars.h"
#include "../include/bitonic_pthread.h"

void pthread_sort() {
    struct pthread_bitonicArgs args;
    // BASECASE = N/P;
    args.lo = 0;
    args.cnt = N;
    args.dir = ASCENDING;
    pthread_recBitonicSort((void *) &args);
}

void *pthread_recBitonicSort(void *pthread_arg) {
    int cnt = ((struct pthread_bitonicArgs *) pthread_arg)->cnt;
    if (cnt > 1) {
        int k = cnt / 2;
        int lo = ((struct pthread_bitonicArgs *) pthread_arg)->lo;
        int dir = ((struct pthread_bitonicArgs *) pthread_arg)->dir;
        if (cnt > BASECASE) {
            pthread_t thread;
            struct pthread_bitonicArgs args_1, args_2, args_3;
            args_1.lo = lo;
            args_1.cnt = k;
            args_1.dir = ASCENDING;
            pthread_create(&thread, NULL, pthread_recBitonicSort, (void *) &args_1);
            args_2.lo = lo + k;
            args_2.cnt = k;
            args_2.dir = DESCENDING;
            pthread_recBitonicSort((void *) &args_2);
            args_3.lo = lo;
            args_3.cnt = cnt;
            args_3.dir = dir;
            pthread_join(thread, NULL);
            pthread_bitonicMerge((void *) &args_3);
        }
        else {
            if (dir == ASCENDING) {
                qsort(a + lo, cnt, sizeof(int), cmp);
            } else {
                qsort(a + lo, cnt, sizeof(int), rcmp);
            }
        }
    }
    return NULL;
}

void *pthread_bitonicMerge(void *pthread_arg) {
    int cnt = ((struct pthread_bitonicArgs *) pthread_arg)->cnt;
    if (cnt > 1) {
        int i;
        int k = cnt / 2;
        int lo = ((struct pthread_bitonicArgs *) pthread_arg)->lo;
        int dir = ((struct pthread_bitonicArgs *) pthread_arg)->dir;
        for (i = lo; i < lo + k; i++)
            compare(i, i + k, dir);
        if (cnt > BASECASE) {
            pthread_t thread;
            struct pthread_bitonicArgs args_1, args_2;
            args_1.lo = lo;
            args_1.cnt = k;
            args_1.dir = dir;
            pthread_create(&thread, NULL,  pthread_bitonicMerge, (void *) &args_1);
            args_2.lo = lo + k;
            args_2.cnt = k;
            args_2.dir = dir;
            pthread_bitonicMerge((void *) &args_2);
            pthread_join(thread, NULL);
        }
        else {
            if (k > 1) {
                struct pthread_bitonicArgs args_1, args_2;
                args_1.lo = lo;
                args_1.cnt = k;
                args_1.dir = dir;
                pthread_bitonicMerge((void *) &args_1);
                args_2.lo = lo + k;
                args_2.cnt = k;
                args_2.dir = dir;
                pthread_bitonicMerge((void *) &args_2);
            }
        }
    }
    return NULL;
}

static inline void exchange(int i, int j) {
    int t;
    t = a[i];
    a[i] = a[j];
    a[j] = t;
}

static inline void compare(int i, int j, int dir) {
    if (dir == (a[i] > a[j]))
        exchange(i, j);
}

static inline int cmp(const void *p, const void *q){
       return ( *(int*)p - *(int*)q );
}

static inline int rcmp(const void *p, const void *q){
       return ( *(int*)p - *(int*)q )*(-1);
}
