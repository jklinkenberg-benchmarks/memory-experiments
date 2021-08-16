#!/usr/local_rwth/bin/zsh

echo "========================================"
echo "===    Latency Tests (lmbench)       ==="
echo "========================================"

N_STRIDES=(8 16 128)
N_REP=3

# display hardware overview
numactl -H

# separator used for matrix output
RES_SEP="\t"
MAX_MEM=256
#BENCH_EXE=lat_mem_rd
BENCH_EXE=lat_mem_rd_specific

# build benchmark once
SCRIPT_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BENCH_DIR="${SCRIPT_DIR}/../../benchmarks/lmbench"
chmod -R u+x ${BENCH_DIR}/scripts
make build --directory=${BENCH_DIR}
 
# get all domains containing CPUs
CPU_DOMAINS="$(numactl -H | grep cpus | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
CPU_DOMAINS=($(echo ${CPU_DOMAINS} | tr ' ' "\n"))
N_CPU_DOMAINS=${#CPU_DOMAINS[@]}

# get all memory domains
MEM_DOMAINS="$(numactl -H | grep free | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
MEM_DOMAINS=($(echo ${MEM_DOMAINS} | tr ' ' "\n"))
N_MEM_DOMAINS=${#MEM_DOMAINS[@]}

echo "Hardware has ${N_CPU_DOMAINS} CPU domains and ${N_MEM_DOMAINS} memory domains"

# initialize result matrices
for cur_stride in "${N_STRIDES[@]}"
do
    eval declare -A matrix_results_stride_${cur_stride}
    for ((i=1;i<=N_CPU_DOMAINS;i++)) do
        for ((j=1;j<=N_MEM_DOMAINS;j++)) do
            eval "matrix_results_stride_${cur_stride}[${i},${j}]=0.0"
        done
    done
done

# run benchmark experiments
for cur_stride in "${N_STRIDES[@]}"
do
    ctr_cpu=1
    for cpu_domain in "${CPU_DOMAINS[@]}"
    do    
        echo "---------------------------------------"
        echo "Domain: ${cpu_domain}"
        
        ctr_mem=1
        for mem_domain in "${MEM_DOMAINS[@]}"
        do
            for rep in {1..${N_REP}}
            do
                echo "Running test for stide ${cur_stride} -- CPU domain ${cpu_domain} and Memory domain ${mem_domain} -- Repetition ${rep}"
            
                export RES_FILE="result_lat_stride_${cur_stride}_node_${cpu_domain}_mem_${mem_domain}_rep_${rep}.log"
                numactl --cpunodebind=${cpu_domain} --membind=${mem_domain} -- ${BENCH_DIR}/bin/x86_64-linux-gnu/${BENCH_EXE} -t -P 1 ${MAX_MEM} ${cur_stride} &> ${RES_FILE}
                eval "matrix_results_stride_${cur_stride}[${ctr_cpu},${ctr_mem}]=$(cat ${RES_FILE} | grep "${MAX_MEM}.000" | awk '{printf "%f", $2}')"
            done
            ctr_mem=$((ctr_mem+1))
        done
        ctr_cpu=$((ctr_cpu+1))
        echo "---------------------------------------"
    done
done

for cur_stride in "${N_STRIDES[@]}"
do
    echo "===== Stride  ${cur_stride} ====="
    echo -n -e "${RES_SEP}"
    for ((j=1;j<=N_MEM_DOMAINS;j++)) do
        echo -n -e "MEM-DOMAIN-$((j-1))${RES_SEP}"
    done
    echo ""

    for ((i=1;i<=N_CPU_DOMAINS;i++)) do
        echo -n -e "CPU-DOMAIN-$((i-1))${RES_SEP}"
        for ((j=1;j<=N_MEM_DOMAINS;j++)) do
            tmp_val=$(echo "\${matrix_results_stride_${cur_stride}[${i},${j}]}")
            tmp_val2=$(eval "echo ${tmp_val}")
            echo -n -e "${tmp_val2}${RES_SEP}"
        done
        echo ""
    done
    echo ""
done
