#!/bin/bash

MACHINE=hikari
ARCH=hwl
COMPILER=intel
C_VER=18.0.2 
MPI_NAME=impi
M_VER=18.0.2
COMPILE_FLAG=xHASWELL

module purge
module reset
module load $COMPILER/$C_VER
module load $MPI_NAME/$M_VER
module load autotools

mkdir ${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG}
cd ${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG}

if [ ! -f ../vpic/configure ]; then
  echo "configure not found!"
  echo "try bootstrap..."
  cd ../vpic/
  ./config/bootstrap
  cd ../${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG}
fi

../vpic/configure CC=mpicc CXX=mpicxx CFLAGS="-O3 -${COMPILE_FLAG} -fno-strict-aliasing -fomit-frame-pointer" CXXFLAGS="-O3 -${COMPILE_FLAG} -fno-strict-aliasing -fomit-frame-pointer -DUSE_V4_SSE -DOMPI_SKIP_MPICXX" MPI_LIBS=" " EXTENSION=${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG}

make -j 8
