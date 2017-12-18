#ifndef BITONIC_SERIAL_H
#define BITONIC_SERIAL_H

#include <stdio.h>
#include <stdlib.h>


#ifndef ASCENDING
#define ASCENDING 1
#endif

#ifndef DESCENDING
#define DESCENDING 0
#endif


void sort(void);

static inline void exchange(int i, int j);

static inline void compare(int i, int j, int dir);

void bitonicMerge(int lo, int cnt, int dir);

void recBitonicSort(int lo, int cnt, int dir);

void impBitonicSort(void);

#endif
