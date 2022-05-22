import os.path

import networkx as nx
from matplotlib import pyplot as plt

data_folder = 'data'
G = nx.read_pajek(os.path.join(data_folder, 'bus-bcn.net'))

x_coord = nx.get_node_attributes(G, 'x')
y_coord = nx.get_node_attributes(G, 'y')

coordinates = {n: (x, y_coord[n]) for n, x in x_coord.items()}
nx.draw(G, pos=coordinates, node_size=2)
plt.show()
