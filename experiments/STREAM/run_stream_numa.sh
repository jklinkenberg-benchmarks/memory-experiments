#!/usr/local_rwth/bin/zsh

# display hardware overview
numactl -H

# separator used for matrix output
RES_SEP="\t"

# build stream once
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
STREAM_DIR="${SCRIPT_DIR}/../../benchmarks/STREAM"
NTIMES=15 STREAM_ARRAY_SIZE=8000000 make stream.icc --directory=${STREAM_DIR}

# get all domains containing CPUs
CPU_DOMAINS="$(numactl -H | grep cpus | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
CPU_DOMAINS=($(echo ${CPU_DOMAINS} | tr ' ' "\n"))
N_CPU_DOMAINS=${#CPU_DOMAINS[@]}

# get all memory domains
MEM_DOMAINS="$(numactl -H | grep free | awk '(NF>3) {printf "%d ", $2}' | sed 's/.$//')"
MEM_DOMAINS=($(echo ${MEM_DOMAINS} | tr ' ' "\n"))
N_MEM_DOMAINS=${#MEM_DOMAINS[@]}

# initialize result matrices
declare -A matrix_results_ser
declare -A matrix_results_8t
for ((i=1;i<=N_CPU_DOMAINS;i++)) do
    for ((j=1;j<=N_MEM_DOMAINS;j++)) do
        matrix_results_ser[$i,$j]=0.0
        matrix_results_8t[$i,$j]=0.0
    done
done

# run STREAM experiments
ctr_cpu=1
for cpu_domain in "${CPU_DOMAINS[@]}"
do    
    echo "---------------------------------------"
    echo "Domain: ${cpu_domain}"

    ctr_mem=1
    for mem_domain in "${MEM_DOMAINS[@]}"
    do
        echo "Running test for CPU domain ${cpu_domain} and Memory domain ${mem_domain}"
        
        export OMP_NUM_THREADS=1
        export RES_FILE="result_node_${cpu_domain}_mem_${mem_domain}_seq.log"
        numactl --cpunodebind=${cpu_domain} --membind=${mem_domain} -- ${STREAM_DIR}/stream.omp.icc &> ${RES_FILE}
        matrix_results_ser[$ctr_cpu,$ctr_mem]=$(cat ${RES_FILE} | grep Triad | awk '{printf "%f", $2}')
        # echo "1 Threads: ${matrix_results_ser[$ctr_cpu,$ctr_mem]} MB/s"

        export OMP_NUM_THREADS=8
        export RES_FILE="result_node_${cpu_domain}_mem_${mem_domain}_8threads.log"
        numactl --cpunodebind=${cpu_domain} --membind=${mem_domain} -- ${STREAM_DIR}/stream.omp.icc &> ${RES_FILE}
        matrix_results_8t[$ctr_cpu,$ctr_mem]=$(cat ${RES_FILE} | grep Triad | awk '{printf "%f", $2}')
        # echo "8 Threads: ${matrix_results_8t[$ctr_cpu,$ctr_mem]} MB/s"

        ctr_mem=$((ctr_mem+1))
    done
    ctr_cpu=$((ctr_cpu+1))
    echo "---------------------------------------"
done

echo "===== Serial Results ====="
echo -n -e "${RES_SEP}"
for ((j=1;j<=N_MEM_DOMAINS;j++)) do
    echo -n -e "MEM-DOMAIN-$((j-1))${RES_SEP}"
done
echo ""

for ((i=1;i<=N_CPU_DOMAINS;i++)) do
    echo -n -e "CPU-DOMAIN-$((i-1))${RES_SEP}"
    for ((j=1;j<=N_MEM_DOMAINS;j++)) do
        echo -n -e "${matrix_results_ser[$i,$j]}${RES_SEP}"
    done
    echo ""
done

echo "===== 8 Thread Results ====="
echo -n -e "${RES_SEP}"
for ((j=1;j<=N_MEM_DOMAINS;j++)) do
    echo -n -e "MEM-DOMAIN-$((j-1))${RES_SEP}"
done
echo ""

for ((i=1;i<=N_CPU_DOMAINS;i++)) do
    echo -n -e "CPU-DOMAIN-$((i-1))${RES_SEP}"
    for ((j=1;j<=N_MEM_DOMAINS;j++)) do
        echo -n -e "${matrix_results_8t[$i,$j]}${RES_SEP}"
    done
    echo ""
done
