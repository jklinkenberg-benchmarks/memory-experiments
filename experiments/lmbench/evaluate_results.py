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
        
        self.stride         = int(tmp_split[3])
        self.cpu_node       = int(tmp_split[5])
        self.mem_node       = int(tmp_split[7])
        self.repetition     = int(tmp_split[9])

        self.arr_size_mb    = -1
        self.latency        = -1

        with open(file_path) as f: lines = [x.strip() for x in list(f)]
        for line in lines:
            if line.strip() != "" and not line.startswith("\"stride"):
                tmp_split           = line.split()
                self.arr_size_mb    = float(tmp_split[0].strip())
                self.latency        = float(tmp_split[1].strip())
                continue

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parses and summarizes latency measurement results for NUMA-aware pointer-chasing benchmark (lmbench)")
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
        if file.endswith(".log") and "result_lat_" in file:
            cur_file_path = os.path.join(args.source, file)
            print(cur_file_path)

            # read file meta data
            file_meta = CFileMetaData(cur_file_path, file)
            list_files.append(file_meta)

    # get unique combinations
    # unique_sizes        = sorted(list(set([x.arr_size_mb for x in list_files])))
    unique_cpu_nodes    = sorted(list(set([x.cpu_node for x in list_files])))
    unique_mem_nodes    = sorted(list(set([x.mem_node for x in list_files])))

    target_file_path    = os.path.join(args.destination, f"data_lat.csv")
    with open(target_file_path, mode="w", newline='') as f_lat:
        writer_lat = csv.writer(f_lat, delimiter=';')

        # write header
        header = ['']
        for i in range(len(unique_mem_nodes)):
            header.append("Mem-Domain " + str(unique_mem_nodes[i]))
        writer_lat.writerow(header)
        
        for cpu_n in unique_cpu_nodes:
            tmp_arr     = [np.nan for x in range(len(unique_mem_nodes))]
            sub         = [x for x in list_files if x.cpu_node == cpu_n]

            for i in range(len(unique_mem_nodes)):
                cur_mem_domain = unique_mem_nodes[i]
                sub2 = [x for x in sub if x.mem_node == cur_mem_domain]
                if len(sub) > 0:
                    tmp_arr[i] = st.mean([x.latency for x in sub2])
            
            # write to csv
            writer_lat.writerow(["CPU-Domain " + str(cpu_n)] + tmp_arr)
        writer_lat.writerow([])