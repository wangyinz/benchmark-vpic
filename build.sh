#!/bin/bash

MACHINE=hikari
ARCH=hwl
COMPILER=intel
C_VER=18.0.2 
MPI_NAME=impi
M_VER=18.0.2
COMPILE_FLAG=-xHASWELL
N_TEST=0
N_TASK=0
NO_BUILD=0

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
    -t|--test)
    N_TEST="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--ntasks-per-node)
    N_TASK="$2"
    shift # past argument
    shift # past value
    ;;
    -nb|--no-build)
    NO_BUILD=1
    shift # past argument
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

mkdir build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_}
cd build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_}

if [ "$NO_BUILD" -eq "0" ]; then
  module load autotools
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
fi

if [ "$N_TEST" -ne "0" ]; then
  if [ -f ../input_files/test_${N_TEST}.cxx ] && \
     [ -f build.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_} ]; then
    cp ../input_files/test_${N_TEST}.cxx ./
    ./build.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_} ./test_${N_TEST}.cxx
    mkdir -p ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}
    cp test_${N_TEST}.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_} ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/

    if [ "$N_TASK" -ne "0" ] && [ "$(($N_TEST%$N_TASK))" -eq "0" ]; then
      cd ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}
      cat > ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/vpic_job.sh << EOF
#!/bin/bash
#SBATCH -J vpic_1152_$(($N_TEST/$N_TASK))
#SBATCH -o vpic_1152.%j 
#SBATCH -N $(($N_TEST/$N_TASK))
#SBATCH --ntasks-per-node ${N_TASK}
#SBATCH -p normal
#SBATCH -t 03:00:00
#SBATCH -A A-ccsc

export vpicexe=${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/test_${N_TEST}.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_FLAG// /_}
export NP=${N_TEST}
export NPPNODE=${N_TASK}

module purge
module load $COMPILER/$C_VER
module load $MPI_NAME/$M_VER

mkdir \${SLURM_JOBID}
cd \${SLURM_JOBID}

date
time ibrun tacc_affinity \${vpicexe} -tpp=1

cp ../vpic_job.sh .
EOF
      sbatch ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/vpic_job.sh
    fi

  fi
fi
