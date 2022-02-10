import argparse
import os, sys
import numpy as np
import statistics as st
import matplotlib.pyplot as plt
import csv

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

        self.avg_time_copy      = -1
        self.avg_time_scale     = -1
        self.avg_time_add       = -1
        self.avg_time_triad     = -1

        with open(file_path) as f: lines = [x.strip() for x in list(f)]
        for line in lines:
            if "Copy:" in line:
                tmp_split = line.split()
                self.bw_copy = float(tmp_split[1].strip())
                self.avg_time_copy = float(tmp_split[2].strip())
                continue
            if "Scale:" in line:
                tmp_split = line.split()
                self.bw_scale = float(tmp_split[1].strip())
                self.avg_time_scale = float(tmp_split[2].strip())
                continue
            if "Add:" in line:
                tmp_split = line.split()
                self.bw_add = float(tmp_split[1].strip())
                self.avg_time_add = float(tmp_split[2].strip())
                continue
            if "Triad:" in line:
                tmp_split = line.split()
                self.bw_triad = float(tmp_split[1].strip())
                self.avg_time_triad = float(tmp_split[2].strip())
                continue

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parses and summarizes bandwidth and execution time measurement results for NUMA-aware STREAM")
    parser.add_argument("-s", "--source",       required=True,  type=str, metavar="<folder path>", help=f"source folder containing outputs")
    parser.add_argument("-d", "--destination",  required=False, type=str, metavar="<folder path>", default=None, help=f"destination folder where resulting data and plots will be stored")
    args = parser.parse_args()

    if not os.path.exists(args.source):
        print(f"Source folder path \"{args.source}\" does not exist")
        sys.exit(1)

     # save results in source folder
    if args.destination is None:
        args.destination = os.path.join(args.source, "result_evaluation")

    if not os.path.exists(args.destination):
        os.makedirs(args.destination)

    list_files = []
    for file in os.listdir(args.source):
        if file.endswith(".log") and "result_bw_threads" in file:
            cur_file_path = os.path.join(args.source, file)
            print(cur_file_path)

            # read file meta data
            file_meta = CFileMetaData(cur_file_path, file)
            list_files.append(file_meta)

    # get unique combinations
    unique_n_threads    = sorted(list(set([x.n_threads for x in list_files])))
    unique_cpu_nodes    = sorted(list(set([x.cpu_node for x in list_files])))
    unique_mem_nodes    = sorted(list(set([x.mem_node for x in list_files])))

    for metric in ['copy', 'scale', 'add', 'triad']:
        target_file_path_bw     = os.path.join(args.destination, f"data_bw_{metric}.csv")
        target_file_path_time   = os.path.join(args.destination, f"data_time_{metric}.csv")
        with open(target_file_path_bw, mode="w", newline='') as f_bw:
            writer_bw = csv.writer(f_bw, delimiter=';')
            with open(target_file_path_time, mode="w", newline='') as f_time:
                writer_time = csv.writer(f_time, delimiter=';')
                for cpu_n in unique_cpu_nodes:
                    writer_bw.writerow(     ["========== CPU-Domain " + str(cpu_n) + " =========="])
                    writer_time.writerow(   ["========== CPU-Domain " + str(cpu_n) + " =========="])
                    # write header
                    header = ['Threads']
                    for i in range(len(unique_mem_nodes)):
                        header.append("Mem-Domain " + str(unique_mem_nodes[i]))
                    writer_bw.writerow(header)
                    writer_time.writerow(header)

                    for cur_thr in unique_n_threads:
                        tmp_arr_data_bw     = [np.nan for x in range(len(unique_mem_nodes))]
                        tmp_arr_data_time   = [np.nan for x in range(len(unique_mem_nodes))]
                        sub = [x for x in list_files if x.cpu_node == cpu_n and x.n_threads == cur_thr]

                        for i in range(len(unique_mem_nodes)):
                            cur_mem_domain = unique_mem_nodes[i]
                            sub2 = [x for x in sub if x.mem_node == cur_mem_domain]
                            if len(sub) > 0:
                                tmp_arr_data_bw[i] = eval(f"st.mean([x.bw_{metric} for x in sub2])")
                                tmp_arr_data_time[i] = eval(f"st.mean([x.avg_time_{metric} for x in sub2])")
                        # write to csv
                        writer_bw.writerow([cur_thr] + tmp_arr_data_bw)
                        writer_time.writerow([cur_thr] + tmp_arr_data_time)
                    writer_bw.writerow([])
                    writer_time.writerow([])