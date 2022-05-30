import os
import pickle
import networkx as nx
import pandas as pd
import small_world as sw
from itertools import chain

data_folder = 'data'
out_folder = 'output'
absolute_out_folder = os.path.join(os.path.dirname(__file__), out_folder)
G = nx.read_pajek(os.path.join(os.path.dirname(__file__), data_folder, 'bus-bcn.net'))

# Read list of lines for each edge
df = pd.read_pickle(os.path.join(os.path.dirname(__file__), data_folder, 'bus-bcn-lines.pkl'))
lines = {
    (u, v, k): df.loc[(df['source'] == u) & (df['target'] == v), 'lines'].values[0] for u, v, k in G.edges(keys=True)
}

# Set the lines for each edge
nx.set_edge_attributes(G, lines, 'lines')

line_names = list(set(chain(*df['lines'].tolist())))
f = open(os.path.join(os.path.dirname(__file__), data_folder, 'line-connections.pkl'), 'rb')
connections = pickle.load(f)
f.close()

# WARNING: when setting load=False, the program will execute methods that take a very long time to finish
sw.plot_diameter_N(G, connections, out_folder=absolute_out_folder, load=True)
sw.plot_shortest_routes(G, lines, out_folder=absolute_out_folder, load=True)
sw.plot_hists(G, out_folder=absolute_out_folder)
sw.small_word_stats(G, out_folder=absolute_out_folder)
