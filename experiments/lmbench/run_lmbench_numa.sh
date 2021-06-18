#!/usr/local_rwth/bin/zsh

# display hardware overview
numactl -H

# separator used for matrix output
RES_SEP="\t"
MAX_MEM=256

# build benchmark once
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
BENCH_DIR="${SCRIPT_DIR}/../../benchmarks/lmbench"
make build --directory=${BENCH_DIR}
 
# get all domains containing CPUs
CPU_DOMAINS="$(numactl -H | grep cpus | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
CPU_DOMAINS=($(echo ${CPU_DOMAINS} | tr ' ' "\n"))
N_CPU_DOMAINS=${#CPU_DOMAINS[@]}

# get all memory domains
MEM_DOMAINS="$(numactl -H | grep free | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
MEM_DOMAINS=($(echo ${MEM_DOMAINS} | tr ' ' "\n"))
N_MEM_DOMAINS=${#MEM_DOMAINS[@]}

# initialize result matrices
declare -A matrix_results_stride8
declare -A matrix_results_stride16
for ((i=1;i<=N_CPU_DOMAINS;i++)) do
    for ((j=1;j<=N_MEM_DOMAINS;j++)) do
        matrix_results_stride8[$i,$j]=0.0
        matrix_results_stride16[$i,$j]=0.0
    done
done

# run benchmark experiments
ctr_cpu=1
for cpu_domain in "${CPU_DOMAINS[@]}"
do    
    echo "---------------------------------------"
    echo "Domain: ${cpu_domain}"

    ctr_mem=1
    for mem_domain in "${MEM_DOMAINS[@]}"
    do
        echo "Running test for CPU domain ${cpu_domain} and Memory domain ${mem_domain}"
        
        export RES_FILE="result_node_${cpu_domain}_mem_${mem_domain}_stride_8.log"
        numactl --cpunodebind=${cpu_domain} --membind=${mem_domain} -- ${BENCH_DIR}/lat_mem_rd -t -P 1 ${MAX_MEM} 8 &> ${RES_FILE}
        matrix_results_stride8[$ctr_cpu,$ctr_mem]=$(cat ${RES_FILE} | grep "${MAX_MEM}.000" | awk '{printf "%f", $2}')
        echo "Stride  8: ${matrix_results_stride8[$ctr_cpu,$ctr_mem]}"

        export RES_FILE="result_node_${cpu_domain}_mem_${mem_domain}_stride_16.log"
        numactl --cpunodebind=${cpu_domain} --membind=${mem_domain} -- ${BENCH_DIR}/lat_mem_rd -t -P 1 ${MAX_MEM} 16 &> ${RES_FILE}
        matrix_results_stride16[$ctr_cpu,$ctr_mem]=$(cat ${RES_FILE} | grep "${MAX_MEM}.000" | awk '{printf "%f", $2}')
        echo "Stride 16: ${matrix_results_stride16[$ctr_cpu,$ctr_mem]}"

        ctr_mem=$((ctr_mem+1))
    done
    ctr_cpu=$((ctr_cpu+1))
    echo "---------------------------------------"
done

echo "===== Stride  8 ====="
echo -n -e "${RES_SEP}"
for ((j=1;j<=N_MEM_DOMAINS;j++)) do
    echo -n -e "MEM-DOMAIN-$((j-1))${RES_SEP}"
done
echo ""

for ((i=1;i<=N_CPU_DOMAINS;i++)) do
    echo -n -e "CPU-DOMAIN-$((i-1))${RES_SEP}"
    for ((j=1;j<=N_MEM_DOMAINS;j++)) do
        echo -n -e "${matrix_results_stride8[$i,$j]}${RES_SEP}"
    done
    echo ""
done

echo "===== Stride 16 ====="
echo -n -e "${RES_SEP}"
for ((j=1;j<=N_MEM_DOMAINS;j++)) do
    echo -n -e "MEM-DOMAIN-$((j-1))${RES_SEP}"
done
echo ""

for ((i=1;i<=N_CPU_DOMAINS;i++)) do
    echo -n -e "CPU-DOMAIN-$((i-1))${RES_SEP}"
    for ((j=1;j<=N_MEM_DOMAINS;j++)) do
        echo -n -e "${matrix_results_stride16[$i,$j]}${RES_SEP}"
    done
    echo ""
done
