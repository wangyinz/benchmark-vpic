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
N_THREAD=1
NO_BUILD=0
QUEUE=normal
HELP=0

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
    -mp|--mpi)
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
    -tr|--nthreads)
    N_THREAD="$2"
    shift # past argument
    shift # past value
    ;;
    -q|--queue)
    QUEUE="$2"
    shift # past argument
    shift # past value
    ;;
    -nb|--no-build)
    NO_BUILD=1
    shift # past argument
    ;;
    -h|--help)
    HELP=1
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


if [ "$HELP" -eq "1" ]; then
  echo "Usage: $0 [-options]"
  echo "  -h  | --help	    	  : This message "
  echo "  -m  | --machine    	  : name of this machine (hikari)" 
  echo "  -a  | --architecture    : name of target architecture (hwl)" 
  echo "  -c  | --compiler	  : compiler to build with (intel)"
  echo "  -cv | --c_version	  : version of the compiler (18.0.2)"
  echo "  -mp | --mpi     	  : MPI to to build with (impi)"
  echo "  -mv | --m_version	  : version of the MPI (18.0.2)"
  echo "  -f  | --flag		  : architecture related flag (-xHASWELL)"
  echo "  -t  | --test		  : create and run test with given number"
  echo "  -n  | --ntasks-per-node : tasks per node for the test"
  echo "  -tr | --nthreads	  : number of threads for the test (1)"
  echo "  -q  | --queue		  : queue to submit the job (normal)"
  echo "  -nb | --no-build	  : skip the build steps"
  echo ""
  echo "Examples:"
  echo "  ./build.sh -m s2 -a knl -c intel -cv 18.0.2 -mp impi -mv 18.0.2 -f \"-xCORE-AVX2 -axCORE-AVX512,MIC-AVX512\""
  echo "  ./build.sh -m s2 -a knl -c intel -cv 18.0.2 -mp impi -mv 18.0.2 -f \"-xCORE-AVX2 -axCORE-AVX512,MIC-AVX512\" -nb -t 1152 -n 16 -tr 4 -q normal"
  exit
fi
  
module purge
module reset
module load $COMPILER/$C_VER
module load $MPI_NAME/$M_VER

TEMP_V=${COMPILE_FLAG// /_}
COMPILE_F=${TEMP_V//,/}

mkdir build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F}
cd build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F}

if [ "$NO_BUILD" -eq "0" ]; then
  module load autotools
  if [ ! -f ../vpic/configure ]; then
    echo "configure not found!"
    git submodule update --init
    git submodule update --remote
    echo "try bootstrap..."
    cd ../vpic/
    ./config/bootstrap
    cd ../build_${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F}
  fi
  
  ../vpic/configure CC=mpicc CXX=mpicxx CFLAGS="-O3 ${COMPILE_FLAG} -fno-strict-aliasing -fomit-frame-pointer" CXXFLAGS="-O3 ${COMPILE_FLAG} -fno-strict-aliasing -fomit-frame-pointer -DUSE_V4_SSE -DOMPI_SKIP_MPICXX" MPI_LIBS=" " EXTENSION=${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F}
  
  make -j 8
fi

if [ "$N_TEST" -ne "0" ]; then
  if [ -f ../input_files/test_${N_TEST}.cxx ] && \
     [ -f build.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F} ]; then
    cp ../input_files/test_${N_TEST}.cxx ./
    ./build.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F} ./test_${N_TEST}.cxx

    if [ "$N_TASK" -ne "0" ] && [ "$(($N_TEST%$N_TASK))" -eq "0" ]; then
      mkdir -p ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}
      cp test_${N_TEST}.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F} ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/
      cd ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}
      cat > ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/vpic_job.sh << EOF
#!/bin/bash
#SBATCH -J vpic_${N_TEST}_$(($N_TEST/$N_TASK))
#SBATCH -o vpic_${N_TEST}.%j 
#SBATCH -N $(($N_TEST/$N_TASK))
#SBATCH --ntasks-per-node ${N_TASK}
#SBATCH -p ${QUEUE}
#SBATCH -t 03:00:00
#SBATCH -A A-ccsc

export OMP_NUM_THREADS=${N_THREAD}

export vpicexe=${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/test_${N_TEST}.${MACHINE}_${ARCH}_${COMPILER}-${C_VER}_${MPI_NAME}-${M_VER}_${COMPILE_F}
export NP=${N_TEST}
export NPPNODE=${N_TASK}

module purge
module load $COMPILER/$C_VER
module load $MPI_NAME/$M_VER

mkdir \${SLURM_JOBID}
cd \${SLURM_JOBID}

date
time ibrun tacc_affinity \${vpicexe} -tpp=${N_THREAD}

cp ../vpic_job.sh .
EOF
      sbatch ${SCRATCH}/benchmarks/vpic/${ARCH}/${N_TEST}/vpic_job.sh
    else
      echo "warning: ntasks-per-node is not currectly given!"
      echo "  test number should be divisible by ntasks-per-node"
    fi
  else
    echo "warning: cannot find the specified test or build!"
  fi
fi
