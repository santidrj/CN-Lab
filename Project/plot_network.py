import os.path

import networkx as nx
from matplotlib import pyplot as plt
from shapely.geometry import Point

data_folder = 'data'
G = nx.read_pajek(os.path.join(data_folder, 'bus-bcn.net'))

x_coord = nx.get_node_attributes(G, 'x')
y_coord = nx.get_node_attributes(G, 'y')

coordinates = {n: Point(x, y_coord[n]) for n, x in x_coord.items()}
nx.draw(G, pos=coordinates, node_size=100)
plt.show()
