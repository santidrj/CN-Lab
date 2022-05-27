import os

import geopandas
import igraph as ig
import matplotlib.pyplot as plt
import networkx as nx
import networkx.algorithms.community as nx_comm
import seaborn as sns
from contextily import add_basemap
from igraph import Graph
from networkx import MultiGraph

data_folder = 'data'
g = Graph.Load(os.path.join(data_folder, 'bus-bcn.net'), format='pajek')
net_data = geopandas.read_file(os.path.join(data_folder, 'raw', 'parades_linia.json'))
crs = net_data.crs.to_string()
del net_data
comms = g.community_infomap(edge_weights='weight')
fig, ax = plt.subplots(figsize=(10, 10))
n_comm = 10
for i in range(n_comm):
    ig.plot(comms.subgraph(i), target=ax, vertex_size=5, vertex_color=sns.color_palette(n_colors=n_comm)[i])
ax.set_xlim(min(g.vs['x']) - 0.01, max(g.vs['x']) + 0.01)
ax.set_ylim(min(g.vs['y']) - 0.01, max(g.vs['y']) + 0.01)
add_basemap(ax, crs=crs)
plt.show()
print(len(comms))

nx_g = nx.read_pajek(os.path.join(data_folder, 'bus-bcn.net'))
assert nx.number_of_selfloops(nx_g) == 0
comms = nx_comm.louvain_communities(MultiGraph(nx_g), resolution=0.25)
x_coord = nx.get_node_attributes(nx_g, 'x')
y_coord = nx.get_node_attributes(nx_g, 'y')
coordinates = {n: (x, y_coord[n]) for n, x in x_coord.items()}

nodes = []
colors = []
color_palette = sns.color_palette(n_colors=n_comm)
n_comm = 5
for i in range(n_comm):
    nodes.extend(list(comms[i]))
    colors.extend([color_palette[i]] * len(comms[i]))

fig, ax = plt.subplots(figsize=(10, 10))

nx.draw(
    nx.subgraph(nx_g, nodes),
    pos=coordinates,
    nodelist=nodes,
    ax=ax,
    node_size=4,
    node_color=colors,
    width=0.5,
    arrowsize=5,
)
ax.set_xlim(min(g.vs['x']) - 0.01, max(g.vs['x']) + 0.01)
ax.set_ylim(min(g.vs['y']) - 0.01, max(g.vs['y']) + 0.01)
add_basemap(ax, crs=crs)
plt.show()
print(len(comms))
