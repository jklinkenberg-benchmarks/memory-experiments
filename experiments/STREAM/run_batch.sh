#!/usr/local_rwth/bin/zsh
#SBATCH --time=03:00:00
#SBATCH --exclusive
#SBATCH --partition=c18m
#SBATCH --nodes=1

hostname
module switch intel intel/19.1
module list

RESULT_POSTFIX=${RESULT_POSTFIX:-""}
RESULT_DIR_NORMAL=${RESULT_DIR_NORMAL:-"results_${RESULT_POSTFIX}_normal"}
RESULT_DIR_READ_ONLY=${RESULT_DIR_READ_ONLY:-"results_${RESULT_POSTFIX}_read-only"}

# remember current directory
CUR_DIR=$(pwd)

# ===== normal STREAM =====
export READ_ONLY=0
mkdir ${RESULT_DIR_NORMAL} && cd ${RESULT_DIR_NORMAL}
zsh ../run_stream_numa.sh
cd ${CUR_DIR}

# ===== read-only STREAM =====
export READ_ONLY=1
export READ_ONLY_REDUCTION=1
mkdir ${RESULT_DIR_READ_ONLY} && cd ${RESULT_DIR_READ_ONLY}
zsh ../run_stream_numa.sh

# ===== Latency tests =====
# zsh ./run_stream_latency.sh

