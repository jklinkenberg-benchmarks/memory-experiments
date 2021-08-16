#!/usr/local_rwth/bin/zsh
#SBATCH --time=01:00:00
#SBATCH --exclusive
#SBATCH --partition=c18m
#SBATCH --nodes=1

hostname
module switch intel intel/19.1
module list

zsh ./run_stream_numa.sh
# zsh ./run_stream_latency.sh

