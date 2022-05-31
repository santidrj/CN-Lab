import os.path

import geopandas
import igraph as ig
import networkx as nx
from contextily import add_basemap
from igraph import Graph
from matplotlib import pyplot as plt

data_folder = 'data'
out_folder = "output"
with_map = True

if with_map:
    addition = 0.005
    g = Graph.Load(os.path.join(data_folder, "bus-bcn.net"), format="pajek")
    net_data = geopandas.read_file(os.path.join(data_folder, "raw", "parades_linia.json"))
    crs = net_data.crs.to_string()
    del net_data

    fig, ax = plt.subplots(figsize=(10, 10))
    ig.plot(g, target=ax, vertex_size=3, edge_width=0.5, edge_arrow_size=1.2)

    ax.set_xlim(min(g.vs["x"]) - addition, max(g.vs["x"]) + addition)
    ax.set_ylim(min(g.vs["y"]) - addition, max(g.vs["y"]) + addition)
    ax.axis("off")
    ax.set_aspect("auto")
    fig.tight_layout()
    add_basemap(ax, crs=crs)
    plt.savefig(os.path.join(out_folder, "bus-bcn.png"))
    plt.show()
else:
    G = nx.read_pajek(os.path.join(data_folder, 'bus-bcn.net'))

    x_coord = nx.get_node_attributes(G, 'x')
    y_coord = nx.get_node_attributes(G, 'y')

    coordinates = {n: (x, y_coord[n]) for n, x in x_coord.items()}
    nx.draw(G, pos=coordinates, node_size=2)
    plt.show()
