import os.path

import geopandas
import networkx as nx
from contextily import add_basemap
from matplotlib import pyplot as plt

data_folder = "data"
net_data = geopandas.read_file(os.path.join(data_folder, "raw", "parades_linia.json"))
G = nx.read_pajek(os.path.join(data_folder, "bus-bcn.net"))

x_coord = nx.get_node_attributes(G, "x")
y_coord = nx.get_node_attributes(G, "y")

coordinates = {n: (x, y_coord[n]) for n, x in x_coord.items()}
fig, ax = plt.subplots()
nx.draw(G, ax=ax, pos=coordinates, node_size=2)
add_basemap(ax, crs=net_data.crs.to_string())
plt.show()
