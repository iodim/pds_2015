#ifndef VECTOR
#define VECTOR

#include <stdio.h>
#include <stdlib.h>

typedef struct point3D {
  float x;
  float y;
  float z;
} point3D;

typedef struct {
  int size;
  int capacity;
  point3D *data;
} Vector;

void vector_init(Vector *vector, int init_cap);

void vector_append(Vector *vector, point3D value);

point3D vector_get(Vector *vector, int index);

void vector_set(Vector *vector, int index, point3D value);

void vector_double_capacity_if_full(Vector *vector);

void vector_reset_index(Vector *vector);

void vector_free(Vector *vector);

#endif
