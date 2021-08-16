#!/usr/local_rwth/bin/zsh

echo "========================================"
echo "===         Bandwidth Tests          ==="
echo "========================================"

# N_THREADS=(1 4 8 12 16 20 24 28 32 36 40 44 48)
N_THREADS=(1 4 8 12 16 20 24 28 32 36 40)
N_REP=3

# display hardware overview
numactl -H

# separator used for matrix output
RES_SEP="\t"

# build benchmark once
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BENCH_DIR="${SCRIPT_DIR}/../../benchmarks/STREAM"
NTIMES=15 STREAM_ARRAY_SIZE=8000000 make stream.icc --directory=${BENCH_DIR}

# get all domains containing CPUs
CPU_DOMAINS="$(numactl -H | grep cpus | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
CPU_DOMAINS=($(echo ${CPU_DOMAINS} | tr ' ' "\n"))
N_CPU_DOMAINS=${#CPU_DOMAINS[@]}

# get all memory domains
MEM_DOMAINS="$(numactl -H | grep free | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
MEM_DOMAINS=($(echo ${MEM_DOMAINS} | tr ' ' "\n"))
N_MEM_DOMAINS=${#MEM_DOMAINS[@]}

echo "Hardware has ${N_CPU_DOMAINS} CPU domains and ${N_MEM_DOMAINS} memory domains"

# run benchmark experiments
for cpu_domain in "${CPU_DOMAINS[@]}"
do    
    echo "---------------------------------------"
    echo "Domain: ${cpu_domain}"
    for mem_domain in "${MEM_DOMAINS[@]}"
    do
        for n_thr in "${N_THREADS[@]}"
        do
            for rep in {1..${N_REP}}
            do
                echo "Running test for ${n_thr} Threads -- CPU domain ${cpu_domain} and Memory domain ${mem_domain} -- Repetition ${rep}"
                
                export OMP_NUM_THREADS=${n_thr}
                export RES_FILE="result_bw_threads_${n_thr}_node_${cpu_domain}_mem_${mem_domain}_rep_${rep}.log"
                numactl --cpunodebind=${cpu_domain} --membind=${mem_domain} -- ${BENCH_DIR}/stream.omp.icc &> ${RES_FILE}
            done
    done
    echo "---------------------------------------"
done