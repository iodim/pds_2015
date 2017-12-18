#ifndef BITONIC_PTHREAD_H
#define BITONIC_PTHREAD_H

#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>


#ifndef ASCENDING
#define ASCENDING 1
#endif

#ifndef DESCENDING
#define DESCENDING 0
#endif


struct pthread_bitonicArgs {
  int lo;
  int cnt;
  int dir;
};


void pthread_sort();

void *pthread_recBitonicSort(void *pthread_arg);

void *pthread_bitonicMerge(void *pthread_arg);

static inline void exchange(int i, int j);

static inline void compare(int i, int j, int dir);

static inline int cmp(const void *p, const void *q);

static inline int rcmp(const void *p, const void *q);

#endif
