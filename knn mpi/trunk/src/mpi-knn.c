#include "../include/vector.h"
#include "../include/mpi-knn.h"

#define DBG 0
#define VRB 0

float rand01() {
  return 0.999999*rand()/((float) RAND_MAX + 1);
}

int box_is_valid(int x, int y, int z, int n, int m, int k) {
  int condition;
  condition = !(x < 0 || y < 0 || z <0);
  condition &= !(x >= n || y >= m || z >= k);
  return condition;
}

void init_neighbors(int * arr, int * size) {
  int i;
  *size = 0;
  for (i = 0; i < 27; i++) {
    arr[i] = -1;
  }
}

void neighbors_reset(int * arr, int * size) {
  *size = 0;
}

void append(int * arr, int *size, int val) {
  arr[(*size)++] = val;
}

int contains(int * arr, int size, int val) {
int i;
  for (i = 0; i < size; i++) {
    if (arr[i] == val) {
      return 1;
    }
  }
  return 0;
}

float inline dist(point3D q, point3D c) {
  return sqrt(pow(q.x - c.x, 2) + pow(q.y - c.y, 2) + pow(q.z - c.z, 2));
}


int main (int argc, char* argv[]) {
  int i, j, l, n, m, k, w, h, d, p, nmk;
  int rank, size;
  int verify;
  point3D q, c;
  long int local_seed;
  long int N_Q, N_C;

  struct timeval startwtime, endwtime;
  double seq_time;

  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  MPI_Status mpistat;
  MPI_Request mpireq[size];

  N_Q = 1 << atoi(argv[1]);
  N_C = 1 << atoi(argv[2]);
  nmk = atoi(argv[3]);
  verify = atoi(argv[4]);

  local_seed = time(NULL) + 100 * rank;
  srand(local_seed);

  // Determine process grid steps
  // w <= h <= d
  p = (int) log2(size);
  if (p % 3 == 0) {
    w = 1 << (p / 3);
    h = 1 << (p / 3);
    d = 1 << (p / 3);
  }
  else if (p % 3 == 1) {
    w = 1 << (p / 3);
    h = 1 << (p / 3);
    d = 1 << (p / 3 + 1);
  }
  else {
    w = 1 << (p / 3);
    h = 1 << (p / 3 + 1);
    d = 1 << (p / 3 + 1);
  }
  if (DBG) printf("w, h, d: %d, %d, %d\n", w, h, d);

  // Determine global grid steps
  // n <= m <= k
  if (nmk % 3 == 0) {
    n = 1 << (nmk / 3);
    m = 1 << (nmk / 3);
    k = 1 << (nmk / 3);
  }
  else if (nmk % 3 == 1) {
    n = 1 << (nmk / 3);
    m = 1 << (nmk / 3);
    k = 1 << (nmk / 3 + 1);
  }
  else {
    n = 1 << (nmk / 3);
    m = 1 << (nmk / 3 + 1);
    k = 1 << (nmk / 3 + 1);
  }
  if (DBG) printf("n, m, k: %d, %d, %d\n", n, m, k);

  if (rank == 0) {
    printf("P = %d\n", size);
    printf("N_Q = %d\n", N_Q);
    printf("N_C = %d\n", N_C);
    printf("nmk = 2^%d\n", nmk);
    printf("n, m, k: %d, %d, %d\n", n, m, k);
  }


  int rank_x, rank_y, rank_z;
  rank_x = rank % w;
  rank_y = ((rank - rank_x)/w) % h;
  rank_z = ((rank - rank_x)/w - rank_y)/h;

  //printf("R%d: %d, %d, %d\n", rank, rank_x, rank_y, rank_z);
  Vector q_local_subset, c_local_subset;

  if (verify) {
    vector_init(&q_local_subset, N_Q/size);
    vector_init(&c_local_subset, N_C/size);
  }

  // Generate Q set and distribute it
  // Initialize the array of process vectors
  Vector process_vectors[size];
  for (i = 0; i < size; i++) {
    vector_init(&process_vectors[i], N_Q/(int)pow(size, 2)|1);
  }

  // 3-D Coordinates for the process grid

  int recv_size;
  point3D * recv_data;
  int dest_box_x, dest_box_y, dest_box_z, dest_box;  // relative grid box coords
  int dest_rank_x, dest_rank_y, dest_rank_z, dest_rank;

  // Generate N_Q points and distribute them accordingly in the process vector
  for (i = 0; i < N_Q/size; i ++) {
    q.x = rand01();
    q.y = rand01();
    q.z = rand01();
    dest_rank_x = (int) floor(q.x * w);
    dest_rank_y = (int) floor(q.y * h);
    dest_rank_z = (int) floor(q.z * d);
    dest_rank = dest_rank_x + dest_rank_y*w + dest_rank_z*w*h;
    if (dest_rank >= size || (DBG && VRB)) {
      printf("%d, %d, %d -> %d\n", dest_rank_x, dest_rank_y, dest_rank_z, dest_rank);
      printf("R%d created: %f, %f, %f, will send to R%d\n", rank, q.x, q.y, q.z, dest_rank);
    }
    vector_append(&process_vectors[dest_rank], q);
    if (verify) vector_append(&q_local_subset, q);
  }

  //MPI_Barrier(MPI_COMM_WORLD);


  Vector q_box_vectors[(1 << nmk)/size];
  for (i = 0; i < (1 << nmk)/size; i++) {
    vector_init(&q_box_vectors[i], N_Q/(1 << nmk)|1);
  }

  MPI_Barrier(MPI_COMM_WORLD);
  if (rank == 0) gettimeofday(&startwtime, NULL);

  for (i = 0; i < size; i++) {
    if (i == rank) {
      for (j = 0; j < size; j++) {
        if (j != rank) {
          if (DBG) printf("R%d sending to R%d\n", i, j);
          MPI_Send(process_vectors[j].data, process_vectors[j].size * sizeof(point3D), MPI_BYTE, j, 1, MPI_COMM_WORLD);
        }
        else {
          for (l = 0; l < process_vectors[rank].size; l++) {
            q = process_vectors[rank].data[l];
            dest_box_x = (int) floor(q.x * n) - rank_x*n/w;
            dest_box_y = (int) floor(q.y * m) - rank_y*m/h;
            dest_box_z = (int) floor(q.z * k) - rank_z*k/d;
            dest_box = dest_box_x + dest_box_y*n/w + dest_box_z*n/w*m/h;
            if (dest_box >= (1 << nmk)/size || (DBG && VRB)) {
              printf("%d, %d, %d -> %d\n", dest_box_x, dest_box_y, dest_box_z, dest_box);
              printf("R%d: %f, %f, %f in B%d\n", rank, q.x, q.y, q.z, dest_box);
            }
            vector_append(&q_box_vectors[dest_box], q);
          }
        }
      }
    }
    else {
      MPI_Probe(MPI_ANY_SOURCE, 1, MPI_COMM_WORLD, &mpistat);
      MPI_Get_count(&mpistat, MPI_BYTE, &recv_size);
      if (DBG) printf("R%d receiving %d elements from R%d\n", rank, recv_size/(int)sizeof(point3D), mpistat.MPI_SOURCE);
      recv_data = (point3D *) malloc(recv_size);
      MPI_Recv(recv_data, recv_size, MPI_BYTE, MPI_ANY_SOURCE, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      for (j = 0; j < recv_size/sizeof(point3D); j++) {
        q = recv_data[j];
        dest_box_x = (int) floor(q.x * n) - rank_x*n/w;
        dest_box_y = (int) floor(q.y * m) - rank_y*m/h;
        dest_box_z = (int) floor(q.z * k) - rank_z*k/d;
        dest_box = dest_box_x + dest_box_y*n/w + dest_box_z*n/w*m/h;
        if (dest_box >= (1 << nmk)/size || (DBG && VRB)) {
          //printf("%d, %d, %d -> %d\n", dest_box_x, dest_box_y, dest_box_z, dest_box);
          printf("R%d: %f, %f, %f in B%d\n", rank, q.x, q.y, q.z, dest_box);
        }
        vector_append(&q_box_vectors[dest_box], q);
      }
      free(recv_data);
    }
  }



  // Generate C set and distribute it
  for (i = 0; i < size; i++) {
    vector_reset_index(&process_vectors[i]);
  }

  int e1, e2, e3;
  int gbox_x, gbox_y, gbox_z; // global grid box coords
  int neighbors[27];
  int neighbors_size;
  init_neighbors(neighbors, &neighbors_size);

  for (i = 0; i < N_Q/size; i ++) {
    c.x = rand01();
    c.y = rand01();
    c.z = rand01();
    if (verify) vector_append(&c_local_subset, c);
    neighbors_reset(neighbors, &neighbors_size);
    gbox_x = (int) floor(c.x * n);
    gbox_y = (int) floor(c.y * m);
    gbox_z = (int) floor(c.z * k);
    for (e1 = gbox_x - 1; e1 < gbox_x + 2; e1++) {
      for (e2 = gbox_y - 1; e2 < gbox_y + 2; e2++) {
        for (e3 = gbox_z - 1; e3 < gbox_z + 2; e3++) {
          if (box_is_valid(e1, e2, e3, n, m, k)) {
            dest_rank_x = (int) floor(e1 * w/n);
            dest_rank_y = (int) floor(e2 * h/m);
            dest_rank_z = (int) floor(e3 * d/k);
            dest_rank = dest_rank_x + dest_rank_y*w + dest_rank_z*w*h;
            if (dest_rank >= size || (DBG && VRB)) {
              //printf("R%d created: %f, %f, %f, will send to R%d\n", rank, q.x, q.y, q.z, dest_rank);
              //printf("%d, %d, %d -> %d\n", e1, e2, e3, dest_rank);
            }
            if (!contains(neighbors, neighbors_size, dest_rank)) {
              append(neighbors, &neighbors_size, dest_rank);
              vector_append(&process_vectors[dest_rank], c);
              if (DBG && VRB) printf("R%d created: %f, %f, %f, will send to R%d\n", rank, c.x, c.y, c.z, dest_rank);
            }
          }
        }
      }
    }
  }



  Vector c_box_vectors[(n/w + 2)*(m/h + 2)*(k/d + 2)];
  for (i = 0; i < (n/w + 2)*(m/h + 2)*(k/d + 2); i++) {
    vector_init(&c_box_vectors[i], N_C/(1 << nmk)|1);
  }

  for (i = 0; i < size; i++) {
    if (i == rank) {
      for (j = 0; j < size; j++) {
        if (j != rank) {
          if (DBG) printf("R%d sending to R%d\n", i, j);
          MPI_Send(process_vectors[j].data, process_vectors[j].size * sizeof(point3D), MPI_BYTE, j, 2, MPI_COMM_WORLD);
        }
        else {
          for (l = 0; l < process_vectors[rank].size; l++) {
            c = process_vectors[rank].data[l];
            dest_box_x = (int) floor(c.x * n) - rank_x*n/w + 1;
            dest_box_y = (int) floor(c.y * m) - rank_y*m/h + 1;
            dest_box_z = (int) floor(c.z * k) - rank_z*k/d + 1;
            dest_box = dest_box_x + dest_box_y*n/w + dest_box_z*n/w*m/h;
            if (dest_box >= (n/w + 2)*(m/h + 2)*(k/d + 2) || (DBG && VRB)) {
              //printf("%d, %d, %d -> %d\n", dest_box_x, dest_box_y, dest_box_z, dest_box);
              printf("R%d: %f, %f, %f in B:%d, %d, %d\n", rank, c.x, c.y, c.z, dest_box_x, dest_box_y, dest_box_z);
            }
            vector_append(&c_box_vectors[dest_box], c);
          }
        }
      }
    }
    else {
      MPI_Probe(MPI_ANY_SOURCE, 2, MPI_COMM_WORLD, &mpistat);
      MPI_Get_count(&mpistat, MPI_BYTE, &recv_size);
      if (DBG) printf("R%d receiving %d elements from R%d\n", rank, recv_size/(int)sizeof(point3D), mpistat.MPI_SOURCE);
      recv_data = (point3D *) malloc(recv_size);
      MPI_Recv(recv_data, recv_size, MPI_BYTE, MPI_ANY_SOURCE, 2, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
      for (j = 0; j < recv_size/sizeof(point3D); j++) {
        c = recv_data[j];
        dest_box_x = (int) floor(c.x * n) - rank_x*n/w + 1;
        dest_box_y = (int) floor(c.y * m) - rank_y*m/h + 1;
        dest_box_z = (int) floor(c.z * k) - rank_z*k/d + 1;
        dest_box = dest_box_x + dest_box_y*n/w + dest_box_z*n/w*m/h;
        if (dest_box >= (n/w + 2)*(m/h + 2)*(k/d + 2) || (DBG && VRB)) {
          //printf("%d, %d, %d -> %d\n", dest_box_x, dest_box_y, dest_box_z, dest_box);
          printf("R%d: %f, %f, %f in B:%d, %d, %d\n", rank, c.x, c.y, c.z, dest_box_x, dest_box_y, dest_box_z);
        }
        vector_append(&c_box_vectors[dest_box], c);
      }
      free(recv_data);
    }
  }

  point3D qnn = {-1, -1, -1};
  float cur_dist, min_dist;
  int box_x, box_y, box_z, box;
  int nbox_x, nbox_y, nbox_z, nbox;

  for (i = 0; i < (1 << nmk)/size; i++) {
    for (j = 0; j < q_box_vectors[i].size; j++) {
      min_dist = 2;
      q = q_box_vectors[i].data[j];
      box_x = (int) floor(q.x * n) - rank_x*n/w + 1;  // Adding + 1
      box_y = (int) floor(q.y * m) - rank_y*m/h + 1;  // to make Q and C
      box_z = (int) floor(q.z * k) - rank_z*k/d + 1;  // indexes the same
      box = box_x + box_y*n/w + box_z*n/w*m/h;
      //printf("q in B: %d, %d, %d\n", box_x, box_y, box_z);
      for (l = 0; l < c_box_vectors[box].size; l++) {
        c = c_box_vectors[box].data[l];
        cur_dist = dist(q, c);
        if (cur_dist < min_dist) {
          qnn = c;
          min_dist = cur_dist;
        }
      }
      float norm_x[3] = {((float) box_x - 1)*w/n, q.x, ((float) box_x)*w/n};
      float norm_y[3] = {((float) box_y - 1)*h/m, q.y, ((float) box_y)*h/m};
      float norm_z[3] = {((float) box_z - 1)*d/k, q.z, ((float) box_z)*d/k};
      neighbors_reset(neighbors, &neighbors_size);
      for (e1 = 0; e1 < 3; e1++) {
        for (e2 = 0; e2 < 3; e2++) {
          for (e3 = 0; e3 < 3; e3++) {
            if (!(norm_x[e1] == q.x && norm_y[e2] == q.y && norm_z[e3] == q.z)) {
              nbox_x = box_x + e1 - 1;
              nbox_y = box_y + e2 - 1;
              nbox_z = box_z + e3 - 1;
              if (box_is_valid(nbox_x, nbox_y, nbox_z, n/w + 2, m/h + 2, k/d + 2) || 1) {
                //printf("%d, %d, %d\n", nbox_x, nbox_y, nbox_z);
                point3D norm = {norm_x[e1], norm_y[e2], norm_z[e3]};
                cur_dist = dist(q, norm);
                if (cur_dist < min_dist) {
                  nbox = nbox_x + nbox_y*n/w + nbox_z*n/w*m/h;
                  for (l = 0; l < c_box_vectors[nbox].size; l++) {
                    c = c_box_vectors[nbox].data[l];
                    cur_dist = dist(q, c);
                    if (cur_dist < min_dist) {
                      qnn = c;
                      min_dist = cur_dist;
                    }
                  }
                }
              }
            }
          }
        }
      }
      if (VRB) printf("q: %f, %f, %f, c: %f, %f, %f, dist: %f\n", q.x, q.y, q.z, qnn.x, qnn.y, qnn.z, min_dist);
      //printf("Q: %d, C: %d\n", i, box);
    }
  }

  MPI_Barrier(MPI_COMM_WORLD);
  if (rank == 0) {
      gettimeofday(&endwtime, NULL);
      seq_time = (double) ((endwtime.tv_usec - startwtime.tv_usec) / 1.0e6 + endwtime.tv_sec - startwtime.tv_sec);
   }

  // Serial naive check for validity
  if (verify) {
    point3D * Q;
    point3D * C;
    if (rank == 0) Q = (point3D *) malloc(N_Q * sizeof(point3D));
    if (rank == 0) C = (point3D *) malloc(N_C * sizeof(point3D));

    // for (i = 1; i < size; i++) {
    //   if (rank == 0) {
    //     MPI_Probe(MPI_ANY_SOURCE, 3, MPI_COMM_WORLD, &mpistat);
    //     MPI_Get_count(&mpistat, MPI_BYTE, &recv_size);
    //     if (DBG) printf("R%d receiving %d elements from R%d\n", rank, recv_size/(int)sizeof(point3D), mpistat.MPI_SOURCE);
    //     recv_data = (point3D *) malloc(recv_size);
    //     MPI_Recv(recv_data, recv_size, MPI_BYTE, MPI_ANY_SOURCE, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    //   }
    //   else if (i == rank) {
    //     MPI_Send(&q_local_subset, q_local_subset.size * sizeof(point3D), MPI_BYTE, 0, MPI_COMM_WORLD);
    //   }
    // }

    MPI_Gather(q_local_subset.data, q_local_subset.size * sizeof(point3D), MPI_BYTE, Q, q_local_subset.size * sizeof(point3D), MPI_BYTE, 0, MPI_COMM_WORLD);
    MPI_Gather(c_local_subset.data, c_local_subset.size * sizeof(point3D), MPI_BYTE, C, c_local_subset.size * sizeof(point3D), MPI_BYTE, 0, MPI_COMM_WORLD);

    if (rank == 0) {
      printf("\n");
      for (i = 0; i < N_Q; i++) {
        min_dist = 2;
        q = Q[i];
        for (j = 0; j < N_C; j++) {
          c = C[j];
          cur_dist = dist(q, c);
          if (cur_dist < min_dist) {
            qnn = c;
            min_dist = cur_dist;
          }
        }
        if (VRB) printf("q: %f, %f, %f, c: %f, %f, %f, dist: %f\n", q.x, q.y, q.z, qnn.x, qnn.y, qnn.z, min_dist);
      }
    }
  }
  MPI_Finalize();

  if (rank == 0) printf("Time elapsed: %f\n", seq_time);

  return 0;

}
