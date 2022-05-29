import os
from pprint import pprint

import geopandas
import igraph as ig
import matplotlib.pyplot as plt
import networkx as nx
import networkx.algorithms.community as nx_comm
import numpy as np
import pandas as pd
import seaborn as sns
from contextily import add_basemap
from igraph import Graph
from networkx import MultiGraph


def nx_com_to_pajek_file(G, comm_list, filepath):
    for c, com in enumerate(comm_list):
        for v in com:
            G.nodes[v]["community"] = c + 1

    n = G.number_of_nodes()
    with open(filepath, "w") as f:
        f.writelines(f"*Vertices {n}\n")
        for node in G.nodes():
            f.writelines(str(G.nodes[node]["community"]) + "\n")


def ig_com_to_pajek_file(comm_list, filepath):
    n = len(comm_list)
    with open(filepath, "w") as f:
        f.writelines(f"*Vertices {n}\n")
        for node_ms in comm_list:
            f.writelines(str(node_ms) + "\n")


data_folder = "data"
out_folder = "output"
g = Graph.Load(os.path.join(data_folder, "bus-bcn.net"), format="pajek")
net_data = geopandas.read_file(os.path.join(data_folder, "raw", "parades_linia.json"))
crs = net_data.crs.to_string()
del net_data
comms = g.community_infomap(edge_weights="weight")
infomap_modularity = comms.modularity
infomap_membership = comms.membership
ig_com_to_pajek_file(infomap_membership, os.path.join(out_folder, "bcn-bus_infomap-communities.clu"))

fig, ax = plt.subplots(figsize=(10, 10))
ig.plot(comms, target=ax, vertex_size=3, edge_width=0, edge_arrow_size=0)
# n_comm = 10
# for i in range(n_comm):
#     ig.plot(comms, target=ax, vertex_size=4, edge_width=0)
addition = 0.001
ax.set_xlim(min(g.vs["x"]) - addition, max(g.vs["x"]) + addition)
ax.set_ylim(min(g.vs["y"]) - addition, max(g.vs["y"]) + addition)
ax.axis("off")
ax.set_aspect("auto")
fig.tight_layout()
add_basemap(ax, crs=crs)
plt.savefig(os.path.join(out_folder, "infomap_community.png"))
plt.show()
print(f"Number of communities detected by Infomap: {len(comms)}")

nx_g = nx.read_pajek(os.path.join(data_folder, "bus-bcn.net"))
assert nx.number_of_selfloops(nx_g) == 0
comms = nx_comm.louvain_communities(MultiGraph(nx_g), resolution=1.0)
louvain_modularity = nx_comm.modularity(nx_g, comms)

nx_com_to_pajek_file(nx_g, comms, os.path.join(out_folder, "bcn-bus_louvain-communities.clu"))

x_coord = nx.get_node_attributes(nx_g, "x")
y_coord = nx.get_node_attributes(nx_g, "y")
coordinates = {n: (x, y_coord[n]) for n, x in x_coord.items()}

nodes = []
colors = []
n_comm = len(comms)
color_palette = sns.color_palette(n_colors=n_comm)
groups = []
for i in range(n_comm):
    nodes.extend(list(comms[i]))
    colors.extend([color_palette[i]] * len(comms[i]))
    groups.append((list(comms[i]), i))

fig, ax = plt.subplots(figsize=(10, 10))
nx.draw_networkx_nodes(
    nx.subgraph(nx_g, nodes),
    pos=coordinates,
    nodelist=nodes,
    ax=ax,
    node_size=10,
    node_color=colors,
)
ax.set_xlim(min(g.vs["x"]) - addition, max(g.vs["x"]) + addition)
ax.set_ylim(min(g.vs["y"]) - addition, max(g.vs["y"]) + addition)
ax.axis("off")
ax.set_aspect("auto")
fig.tight_layout()
add_basemap(ax, crs=crs)
plt.savefig(os.path.join(out_folder, "louvain_community.png"))
plt.show()
print(f"Number of communities detected by Louvain: {len(comms)}")

modularities = pd.DataFrame(
    {"algorithm": ["Infomap", "Louvain"], "modulairty": [infomap_modularity, louvain_modularity]}
)
modularities.set_index("algorithm", inplace=True)
tables_dir = os.path.join(out_folder, "tables")
if not os.path.exists(tables_dir):
    os.makedirs(tables_dir)
outfile = os.path.join(tables_dir, "modularity.tex")
s = modularities.style.highlight_max(props="textbf:--rwrap")
s.to_latex(
    outfile,
    position="!htbp",
    position_float="centering",
    hrules=True,
    label="tab:modularity",
    caption="Network modularity using Infomap and Louvain algorithms.",
)

# Betweenness
betweenness = nx.betweenness_centrality(nx_g, normalized=True, weight="weight")
print("Normalized betweeness")
pprint(betweenness)
stops = list(betweenness.keys())
stop_betweenness = list(betweenness.values())
top_10 = np.argsort(stop_betweenness)[::-1][:10]
print("Top-10 betweenness:")
for i in top_10:
    print(f"{stops[i]}: {stop_betweenness[i]}")

df_betweenness = pd.DataFrame({"Bus stop": np.array(stops)[top_10], "Betweeness": np.array(stop_betweenness)[top_10]})
df_betweenness.set_index("Bus stop", inplace=True)
outfile = os.path.join(tables_dir, "betweenness.tex")
df_betweenness.style.to_latex(
    outfile,
    position="!htbp",
    position_float="centering",
    hrules=True,
    label="tab:betweenness",
    caption="Top-10 bus stop betweenness.",
)
