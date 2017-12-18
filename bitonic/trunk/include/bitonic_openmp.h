#ifndef BITONIC_OPENMP_H
#define BITONIC_OPENMP_H

#include <omp.h>
#include <stdio.h>
#include <stdlib.h>


#ifndef ASCENDING
#define ASCENDING 1
#endif

#ifndef DESCENDING
#define DESCENDING 0
#endif


void openmp_sort();

void openmp_imp_sort();

void openmp_rec_sort(int lo, int cnt, int dir);

void openmp_merge(int lo, int cnt, int dir);

static inline void exchange(int i, int j);

static inline void compare(int i, int j, int dir);

static inline int cmp(const void *p, const void *q);

static inline int rcmp(const void *p, const void *q);

#endif
