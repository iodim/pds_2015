#ifndef BITONIC_CILK_H
#define BITONIC_CILK_H

#include <stdio.h>
#include <stdlib.h>

#include <cilk/cilk.h>
#include <cilk/cilk_api.h>


#ifndef ASCENDING
#define ASCENDING 1
#endif

#ifndef DESCENDING
#define DESCENDING 0
#endif


void cilk_sort();

void cilk_imp_sort();

void cilk_rec_sort(int lo, int cnt, int dir);

void cilk_merge(int lo, int cnt, int dir);

static inline void exchange(int i, int j);

static inline void compare(int i, int j, int dir);

static inline int cmp(const void *p, const void *q);

static inline int rcmp(const void *p, const void *q);

#endif
