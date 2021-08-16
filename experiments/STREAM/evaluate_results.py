import os, sys
import numpy as np
import statistics as st
import matplotlib.pyplot as plt
import csv

script_dir = os.path.abspath(os.path.dirname(os.path.abspath(__file__)))
path_src_folder = "F:\\repos\\benchmarks\\memory-experiments-data\\2021-08-16_Leonide_no_numad\\result_numa"

class CFileMetaData():

    def __init__(self, file_path, file_name):
        # get file name and split
        file_name = file_name.split(".")[0]
        tmp_split = file_name.split("_")
        
        self.n_threads      = int(tmp_split[3])
        self.cpu_node       = int(tmp_split[5])
        self.mem_node       = int(tmp_split[7])
        self.repetition     = int(tmp_split[9])

        self.bw_copy      = -1
        self.bw_scale     = -1
        self.bw_add       = -1
        self.bw_triad     = -1

        with open(file_path) as f: lines = [x.strip() for x in list(f)]
        for line in lines:
            if "Copy:" in line:
                tmp_split = line.split()
                self.bw_copy = float(tmp_split[1].strip())
                continue
            if "Scale:" in line:
                tmp_split = line.split()
                self.bw_scale = float(tmp_split[1].strip())
                continue
            if "Add:" in line:
                tmp_split = line.split()
                self.bw_add = float(tmp_split[1].strip())
                continue
            if "Triad:" in line:
                tmp_split = line.split()
                self.bw_triad = float(tmp_split[1].strip())
                continue

target_folder_data  = os.path.join(path_src_folder, "result_evaluation")
if not os.path.exists(target_folder_data):
    os.makedirs(target_folder_data)

list_files = []

for file in os.listdir(path_src_folder):
    if file.endswith(".log") and "result_bw_threads" in file:
        cur_file_path = os.path.join(path_src_folder, file)
        print(cur_file_path)

        # read file meta data
        file_meta = CFileMetaData(cur_file_path, file)
        list_files.append(file_meta)

# get unique combinations
unique_n_threads    = sorted(list(set([x.n_threads for x in list_files])))
unique_cpu_nodes    = sorted(list(set([x.cpu_node for x in list_files])))
unique_mem_nodes    = sorted(list(set([x.mem_node for x in list_files])))

for metric in ['copy', 'scale', 'add', 'triad']:
    target_file_path = os.path.join(target_folder_data, f"data_{metric}.csv")
    with open(target_file_path, mode="w", newline='') as f:
        writer = csv.writer(f, delimiter=';')        
        for cpu_n in unique_cpu_nodes:
            writer.writerow(["========== CPU-Domain " + str(cpu_n) + " =========="])
            # write header
            header = ['Threads']
            for i in range(len(unique_mem_nodes)):
                header.append("Mem-Domain " + str(unique_mem_nodes[i]))
            writer.writerow(header)

            for cur_thr in unique_n_threads:
                tmp_arr_data = [np.nan for x in range(len(unique_mem_nodes))]
                sub = [x for x in list_files if x.cpu_node == cpu_n and x.n_threads == cur_thr]

                for i in range(len(unique_mem_nodes)):
                    cur_mem_domain = unique_mem_nodes[i]
                    sub2 = [x for x in sub if x.mem_node == cur_mem_domain]
                    if len(sub) > 0:
                        tmp_arr_data[i] = eval(f"st.mean([x.bw_{metric} for x in sub2])")
                # write to csv
                writer.writerow([cur_thr] + tmp_arr_data)
            writer.writerow([])