#include "../include/vector.h"

void vector_init(Vector *vector, int init_cap) {
  vector->size = 0;
  vector->capacity = init_cap;

  vector->data = malloc(sizeof(point3D) * vector->capacity);
}

void vector_append(Vector *vector, point3D value) {
  vector_double_capacity_if_full(vector);
  vector->data[vector->size++] = value;
}

point3D vector_get(Vector *vector, int index) {
  if (index >= vector->size || index < 0) {
    printf("Index %d out of bounds for vector of size %d\n", index, vector->size);
    exit(1);
  }
  return vector->data[index];
}

void vector_set(Vector *vector, int index, point3D value) {
  // zero fill the vector up to the desired index
  point3D zero;
  zero.x = 0;
  zero.y = 0;
  zero.z = 0;
  while (index >= vector->size) {
    vector_append(vector, zero);
  }
  vector->data[index] = value;
}

void vector_double_capacity_if_full(Vector *vector) {
  if (vector->size >= vector->capacity) {
    vector->capacity *= 2;
    vector->data = realloc(vector->data, sizeof(point3D) * vector->capacity);
  }
}

void vector_reset_index(Vector *vector) {
  vector->size = 0;
}

void vector_free(Vector *vector) {
  free(vector->data);
}
