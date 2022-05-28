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
# df = pd.read_pickle(os.path.join(os.path.dirname(__file__), data_folder, 'bus-bcn-lines.pkl'))
# lines = {(u, v, k): df.loc[(df['source'] == u) & (df['target'] == v), 'lines'].values[0] for u, v, k in
#          G.edges(keys=True)}
#
# # Set the lines for each edge
# nx.set_edge_attributes(G, lines, 'lines')
#
# line_names = list(set(chain(*df['lines'].tolist())))
# f = open(os.path.join(os.path.dirname(__file__), data_folder, 'line-connections.pkl'), 'rb')
# connections = pickle.load(f)
# f.close()
# f = open(os.path.join(os.path.dirname(__file__), out_folder, 'transhipment_dict.pkl'), 'rb')
# transhipment_dict = pickle.load(f)
# f.close()
# f = open(os.path.join(os.path.dirname(__file__), out_folder, 'path_length_dict.pkl'), 'rb')
# path_length_dict = pickle.load(f)
# f.close()
#sw.plot_mean_path_N(G, connections, out_folder=os.path.join(os.path.dirname(__file__), out_folder), load=True)
#sw.plot_hists(G, out_folder=os.path.join(os.path.dirname(__file__), out_folder))
#sw.shortest_routes(G, lines, os.path.join(os.path.dirname(__file__), out_folder))
#sw.plot_shortest_routes(transhipment_dict, path_length_dict, os.path.join(os.path.dirname(__file__), out_folder))
sw.small_word_stats(G, os.path.join(os.path.dirname(__file__), out_folder))
