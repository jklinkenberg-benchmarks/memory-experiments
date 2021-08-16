#!/usr/local_rwth/bin/zsh

echo "========================================"
echo "===           Latency Tests          ==="
echo "========================================"

# N_THREADS_PER_DOMAIN=(1 2 4 6 8 10 12 14 16 18 20 22 24)
N_THREADS_PER_DOMAIN=(1 2 4 6 8 10 12 14 16 18 20)
N_REP=3

# display hardware overview
numactl -H

# separator used for matrix output
RES_SEP="\t"

# build benchmark once
SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BENCH_DIR="${SCRIPT_DIR}/../../benchmarks/STREAM"
NTIMES=10 STREAM_ARRAY_SIZE=200000000 make latency.icc --directory=${BENCH_DIR}

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
        for n_thr in "${N_THREADS_PER_DOMAIN[@]}"
        do
            for rep in {1..${N_REP}}
            do
                echo "Running test for ${n_thr} Threads -- CPU domain ${cpu_domain} and Memory domain ${mem_domain} -- Repetition ${rep}"
                
                export OMP_NUM_THREADS=${n_thr}
                export RES_FILE="result_lat_threads_${n_thr}_node_${cpu_domain}_mem_${mem_domain}_rep_${rep}.log"
                numactl --cpunodebind=${cpu_domain} --membind=${mem_domain} -- ${BENCH_DIR}/latency.omp.icc &> ${RES_FILE}
            done
        done
    done
    echo "---------------------------------------"
done