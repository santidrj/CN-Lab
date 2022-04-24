import os
import itertools
import matplotlib.pyplot as plt
import numpy as np
import networkx as nx
import networkx.algorithms.community as nx_comm
from networkx.readwrite.pajek import read_pajek
import time

algorithm = "girvan-newman"


def get_reference(file):
    code = {"dolphins.net": "dolphins-real.clu",
            "football.net": "football-conferences.clu",
            "zachary_unwh.net": "zachary_unwh-real.clu"
            }
    name = os.path.basename(file)
    if name in code.keys():
        ref = file.replace(name, code[name])
    else:
        ref = file.replace(".net", ".clu")
    return ref


def set_node_community(G, communities, n_com=None, n_com_max=50):
    if n_com:
        if n_com > 2:
            comm = next(itertools.islice(communities, n_com - 2, n_com - 1))
            com_list = list(sorted(c) for c in comm)
        else:
            comm = itertools.islice(communities, n_com)
            com_list = list(sorted(c) for c in next(comm))
    else:
        limited = itertools.takewhile(lambda c: len(c) <= n_com_max, communities)
        best_mod = 0
        for communities in limited:
            test_com = list(sorted(c) for c in communities)
            test_mod = nx_comm.modularity(G, test_com)
            if test_mod > best_mod:
                best_mod = test_mod
                com_list = test_com

    for c, com in enumerate(com_list):
        for v in com:
            G.nodes[v]["community"] = c + 1
    return G, com_list


def nx_com_to_pajek_file(G, filepath):
    N = G.number_of_nodes()
    f = open(filepath, "w")
    f.writelines(f"*Vertices {N}\n")
    for node in G.nodes():
        f.writelines(str(G.nodes[node]['community']) + "\n")
    f.close()


def pajek_file_to_nx_com(filepath):
    with open(filepath) as f:
        lines = f.read().splitlines()[1:]
    lines = np.array(lines)
    nodes = np.array(G.nodes)
    comm_list = []
    for c in set(lines):
        c_idx = np.where(lines == c)
        comm_list.append(set(nodes[c_idx]))
    return comm_list


def get_number_com(filepath):
    with open(filepath) as f:
        lines = f.read().splitlines()[1:]
    return len(set(lines))


for root, dirs, files in os.walk("A3-networks"):
    for file in files:
        net_name, ext = file.split(".")
        if ext == "net":
            print(f"Network: {net_name}")

            # Modularity
            ref_file = get_reference(os.path.join(root, file))
            ref_name, ref_ext = os.path.basename(ref_file).split(".")
            ref_files = [os.path.join(root, filename) for filename in os.listdir(root)
                         if filename.startswith(ref_name) and filename.endswith(ref_ext)]

            if not ref_files:
                ref_files = [None]

            for ref_file in ref_files:
                G = read_pajek(os.path.join(root, file))
                com = nx_comm.centrality.girvan_newman(G)
                if ref_file:
                    ref_name, ref_ext = os.path.basename(ref_file).split(".")
                    ref_mod = nx_comm.modularity(G, pajek_file_to_nx_com(ref_file))
                    ref_mod = round(ref_mod, 4)
                    n_com = get_number_com(ref_file)
                else:
                    ref_mod = "-"
                    n_com = None

                print(f"Reference modularity ({ref_name}): {ref_mod}")

                save_name = net_name if len(ref_files) <= 1 else ref_name
                out_file = save_name + "_" + algorithm

                G, com_list = set_node_community(G, com, n_com)
                mod = nx_comm.modularity(G, com_list)
                mod = round(mod, 4)
                print(f"{algorithm.title()} modularity ({ref_name}): {mod}")

                mod_file = os.path.join("results", save_name + "_modularity.csv")

                with open(mod_file, 'r+') as f:
                    lines = f.readlines()
                    f.seek(0)
                    f.truncate()
                    f.writelines(lines[:3])
                    f.writelines(f"{algorithm.title()},{mod},{ref_mod}")

                # Partition
                nx_com_to_pajek_file(G, os.path.join("partitions", out_file + ".clu"))

            print("\n")
