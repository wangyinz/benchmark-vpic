#!/bin/bash

MACHINE=hikari
ARCH=hwl
COMPILER=intel
C_VER=18.0.2 
MPI_NAME=impi
M_VER=18.0.2
COMPILE_FLAG=-xHASWELL

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -m|--machine)
    MACHINE="$2"
    shift # past argument
    shift # past value
    ;;
    -a|--architecture)
    ARCH="$2"
    shift # past argument
    shift # past value
    ;;
    -c|--compiler)
    COMPILER="$2"
    shift # past argument
    shift # past value
    ;;
    -cv|--c_version)
    C_VER="$2"
    shift # past argument
    shift # past value
    ;;
    -m|--mpi)
    MPI_NAME="$2"
    shift # past argument
    shift # past value
    ;;
    -mv|--m_version)
    M_VER="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--flag)
    COMPILE_FLAG="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -n $1 ]]; then
    echo "Last line of file specified as non-opt/last argument:"
    tail -1 "$1"
fi


module purge
module reset
module load $COMPILER/$C_VER
module load $MPI_NAME/$M_VER
module load autotools

mkdir build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_}
cd build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_}

if [ ! -f ../vpic/configure ]; then
  echo "configure not found!"
  git submodule update --init
  git submodule update --remote
  echo "try bootstrap..."
  cd ../vpic/
  ./config/bootstrap
  cd ../build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_}
fi

../vpic/configure CC=mpicc CXX=mpicxx CFLAGS="-O3 ${COMPILE_FLAG} -fno-strict-aliasing -fomit-frame-pointer" CXXFLAGS="-O3 ${COMPILE_FLAG} -fno-strict-aliasing -fomit-frame-pointer -DUSE_V4_SSE -DOMPI_SKIP_MPICXX" MPI_LIBS=" " EXTENSION=${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_}

make -j 8
