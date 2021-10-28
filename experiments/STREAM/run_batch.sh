#!/usr/local_rwth/bin/zsh
#SBATCH --time=03:00:00
#SBATCH --exclusive
#SBATCH --partition=c18m
#SBATCH --nodes=1

hostname
module switch intel intel/19.1
module list

# remember current directory
CUR_DIR=$(pwd)

# ===== normal STREAM =====
export READ_ONLY=0
mkdir results_normal && cd results_normal
zsh ../run_stream_numa.sh
cd ${CUR_DIR}

# ===== read-only STREAM =====
export READ_ONLY=1
export READ_ONLY_REDUCTION=1
mkdir results_read-only && cd results_read-only
zsh ../run_stream_numa.sh

# ===== Latency tests =====
# zsh ./run_stream_latency.sh

