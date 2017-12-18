/*
 bitonic_openmp.c

 Implements bitonic sort with the use of the openmp library.
*/

#include "../include/global_vars.h"
#include "../include/bitonic_openmp.h"


void openmp_sort() {
    omp_set_num_threads(P);
    BASECASE = N/P;
    #pragma omp parallel
    #pragma omp single nowait
    openmp_rec_sort(0, N, ASCENDING);
}

void openmp_imp_sort() {
    int i, j, k;
    for (k = 2; k <= N; k = 2 * k) {
        for (j = k >> 1; j > 0; j = j >> 1) {
            #pragma omp parallel for shared(a, N)
            for (i = 0; i < N; i++) {
                int ij = i ^j;
                if ((ij) > i) {
                    if ((i & k) == 0 && a[i] > a[ij])
                        exchange(i, ij);
                    if ((i & k) != 0 && a[i] < a[ij])
                        exchange(i, ij);
                }
            }
        }
    }

}

void openmp_rec_sort(int lo, int cnt, int dir) {
    if (cnt > 1) {
        if (cnt > BASECASE) {
            int k = cnt / 2;
            #pragma omp task
            openmp_rec_sort(lo, k, ASCENDING);
            // #pragma omp task
            openmp_rec_sort(lo + k, k, DESCENDING);
            #pragma omp taskwait
            openmp_merge(lo, cnt, dir);
        }
        else {
            if (dir == ASCENDING) {
                qsort(a + lo, cnt, sizeof(int), cmp);
            } else {
                qsort(a + lo, cnt, sizeof(int), rcmp);
            }
        }
    }
}

void openmp_merge(int lo, int cnt, int dir) {
    if (cnt > 1) {
        if (cnt > BASECASE) {
            int k = cnt / 2;
            int i;
            for (i = lo; i < lo + k; i++)
                compare(i, i + k, dir);
            #pragma omp task
            openmp_merge(lo, k, dir);
            // #pragma omp task
            openmp_merge(lo + k, k, dir);
            #pragma omp taskwait
        }
        else {
            int k = cnt / 2;
            int i;
            for (i = lo; i < lo + k; i++)
                compare(i, i + k, dir);
            openmp_merge(lo, k, dir);
            openmp_merge(lo + k, k, dir);
        }
    }
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
