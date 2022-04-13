import os
import itertools
import matplotlib.pyplot as plt
import numpy as np
import networkx as nx
import networkx.algorithms.community as nx_comm
from networkx.readwrite.pajek import read_pajek

algorithm = "girvan-newman"
N_COM = 10  # Default number of communities


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


# def to_pajek_com(communities, N):
#     df = pd.DataFrame(index=range(N), columns=[f"*Vertices {N}"])
#     c = 1
#     for com in next(communities):
#         print(list(com))
#         df.iloc[list(com)] = c
#         c += 1
#     return df


def set_node_community(G, communities, n_com):
    limited = itertools.takewhile(lambda c: len(c) <= n_com, communities)
    for communities in limited:
        com_list = list(sorted(c) for c in communities)
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
    lines = np.array(lines, dtype=np.int64)
    return max(lines)


for root, dirs, files in os.walk("A3-networks"):
    for file in files:
        net_name, ext = file.split(".")
        if ext == "net":
            print(f"Network: {net_name}")
            G = read_pajek(os.path.join(root, file))
            com = nx_comm.centrality.girvan_newman(G)

            # Modularity
            ref_file = get_reference(os.path.join(root, file))
            ref_name, ref_ext = os.path.basename(ref_file).split(".")
            ref_files = [filename for filename in os.listdir(root)
                         if filename.startswith(ref_name) and filename.endswith(ext)]

            if not ref_files:
                ref_mod_list = ["-"]
                n_com_list = [N_COM]
            else:
                for ref_file in ref_files:
                    ref_name, ref_ext = os.path.basename(ref_file).split(".")
                    save_name = net_name if len(ref_files) == 1 else ref_name
                    out_file = save_name + "_" + algorithm

                    ref_mod = nx_comm.modularity(G, pajek_file_to_nx_com(ref_file))
                    ref_mod = round(ref_mod, 3)
                    n_com = get_number_com(ref_file)

                    print(f"Reference modularity {ref_name}: {ref_mod}")

                    G, com_list = set_node_community(G, com, n_com)
                    mod = nx_comm.modularity(G, com_list)
                    mod = round(mod, 3)
                    print(f"{algorithm.title()} modularity: {mod}")

                    mod_file = os.path.join("results", save_name + "_modularity.csv")

                    with open(mod_file, 'r+') as f:
                        lines = f.readlines()
                        f.seek(0)
                        f.truncate()
                        f.writelines(lines[:3])
                        f.writelines(f"{algorithm.title()},{mod},{ref_mod}")

                    # Partition
                    nx_com_to_pajek_file(G, os.path.join("nets", out_file + ".clu"))

                    # Plot
                    x = nx.get_node_attributes(G, 'x').values()
                    y = nx.get_node_attributes(G, 'y').values()
                    if x and y:
                        nodes = list(G.nodes())
                        pos = dict(zip(nodes, tuple(zip(x, y))))
                    else:
                        pos = nx.kamada_kawai_layout(G)
                    colors = list(nx.get_node_attributes(G, 'community').values())
                    nx.draw(G,
                            pos=pos,
                            node_size=50,
                            with_labels=False,
                            node_color=colors,
                            cmap=plt.cm.hsv
                            )
                    plt.savefig(os.path.join("figures", out_file + ".png"))
                    print("\n")

"""
G = nx.karate_club_graph()
communities = girvan_newman(G)

node_groups = []
for com in next(communities):
  node_groups.append(list(com))

print(node_groups)

color_map = []
for node in G:
    if node in node_groups[0]:
        color_map.append('blue')
    else: 
        color_map.append('green')  
nx.draw(G, node_color=color_map, with_labels=True)
plt.show()
"""
