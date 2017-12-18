#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>


struct timeval startwtime, endwtime;

double seq_time;

int test(void);

void init(void);

void print(void);

int main(int argc, char **argv);

static inline int cmp(const void *p, const void *q);
