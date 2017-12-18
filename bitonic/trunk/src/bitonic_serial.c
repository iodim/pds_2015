/*
 bitonic_serial.c

 Implements a serial version bitonic sort recursively and imperatively.
*/

#include "../include/global_vars.h"
#include "../include/bitonic_serial.h"


/** function sort()
   Caller of recBitonicSort for sorting the entire array of length N
   in ASCENDING order
 **/
void sort() {
    recBitonicSort(0, N, ASCENDING);
}

/** function recBitonicSort()
    first produces a bitonic sequence by recursively sorting
    its two halves in opposite sorting orders, and then
    calls bitonicMerge to make them in the same order
 **/
void recBitonicSort(int lo, int cnt, int dir) {
    if (cnt > 1) {
        int k = cnt / 2;
        recBitonicSort(lo, k, ASCENDING);
        recBitonicSort(lo + k, k, DESCENDING);
        bitonicMerge(lo, cnt, dir);
    }
}

/** Procedure bitonicMerge()
   It recursively sorts a bitonic sequence in ascending order,
   if dir = ASCENDING, and in descending order otherwise.
   The sequence to be sorted starts at index position lo,
   the parameter cbt is the number of elements to be sorted.
 **/
void bitonicMerge(int lo, int cnt, int dir) {
    if (cnt > 1) {
        int k = cnt / 2;
        int i;
        for (i = lo; i < lo + k; i++)
            compare(i, i + k, dir);
        bitonicMerge(lo, k, dir);
        bitonicMerge(lo + k, k, dir);
    }
}

/*
  imperative version of bitonic sort
*/
void impBitonicSort() {

    int i, j, k;

    for (k = 2; k <= N; k = 2 * k) {
        for (j = k >> 1; j > 0; j = j >> 1) {
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

/** INLINE procedure exchange() : pair swap **/
static inline void exchange(int i, int j) {
    int t;
    t = a[i];
    a[i] = a[j];
    a[j] = t;
}

/** procedure compare()
   The parameter dir indicates the sorting direction, ASCENDING
   or DESCENDING; if (a[i] > a[j]) agrees with the direction,
   then a[i] and a[j] are interchanged.
**/
static inline void compare(int i, int j, int dir) {
    if (dir == (a[i] > a[j]))
        exchange(i, j);
}
