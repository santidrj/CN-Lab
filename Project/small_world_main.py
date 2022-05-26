import os
import pickle

import networkx as nx
import pandas as pd
import small_world as sw
import matplotlib.pyplot as plt
import numpy as np

from itertools import chain

data_folder = 'data'
out_folder = 'output'
G = nx.read_pajek(os.path.join(os.path.dirname(__file__), data_folder, 'bus-bcn.net'))

# Read list of lines for each edge
df = pd.read_pickle(os.path.join(os.path.dirname(__file__), data_folder, 'bus-bcn-lines.pkl'))
lines = {(u, v, k): df.loc[(df['source'] == u) & (df['target'] == v), 'lines'].values[0] for u, v, k in
         G.edges(keys=True)}

# Set the lines for each edge
nx.set_edge_attributes(G, lines, 'lines')
print(nx.number_weakly_connected_components(G))
# print(nx.average_shortest_path_length(G))

line_names = list(set(chain(*df['lines'].tolist())))
f = open(os.path.join(os.path.dirname(__file__), data_folder, 'line-connections.pkl'), 'rb')
connections = pickle.load(f)

load = False
if load:
    f = open(os.path.join(os.path.dirname(__file__), out_folder, 'mean_path_subsets.pkl'), 'rb')
    mean_path_N = pickle.load(f)
    N, mean_path = list(mean_path_N.keys()), list(mean_path_N.values())
else:
    N, mean_path = sw.mean_path_subnets(G, connections, 30, min_lines=20)
    f = open(os.path.join(os.path.dirname(__file__), out_folder, 'mean_path_subsets.pkl'), 'wb')
    pickle.dump(dict(zip(N, mean_path)), f)
    f.close()

fit = np.polyfit(np.log10(N), mean_path, 1)
plt.plot(np.log10(N), mean_path, 'ko-')
plt.plot(np.log10(N), fit[0] * np.log10(N) + fit[1], "k-")
plt.show()
print("Done")
