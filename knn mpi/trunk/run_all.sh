#!/bin/bash
#PBS -q auth
#PBS -N bin/mpi-knn
#PBS -j oe
k=2
while [ $k -lt 20 ]
do
  sed -i '5s/.*/\#PBS \-l nodes='$k'\:ppn=1/' mpi-knn.pbs
  qsub mpi-knn.pbs
  k=`expr $k + $k`
  sleep 1
done
k=2
while [ $k -lt 10 ]
do
  sed -i '5s/.*/\#PBS \-l nodes=16\:ppn='$k'/' mpi-knn.pbs
  qsub mpi-knn.pbs
  k=`expr $k + $k`
  sleep 1
done
