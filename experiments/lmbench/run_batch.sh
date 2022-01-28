#!/usr/local_rwth/bin/zsh
#SBATCH --time=01:00:00
#SBATCH --exclusive
#SBATCH --partition=c18m
#SBATCH --nodes=1

hostname
module switch intel intel/19.1
module list

RESULT_POSTFIX=${RESULT_POSTFIX:-""}
RESULT_DIR=${RESULT_DIR:-"results_${RESULT_POSTFIX}"}

# remember current directory
CUR_DIR=$(pwd)

# execute measurements
mkdir ${RESULT_DIR} && cd ${RESULT_DIR}
zsh ../run_lmbench_numa.sh
cd ${CUR_DIR}
