import os
from pprint import pprint

import networkx as nx
import numpy as np
import pandas as pd
from networkx import DiGraph, NetworkXNoPath
from osgeo.gnm import Network

data_folder = 'data'
G = nx.read_pajek(os.path.join(os.path.dirname(__file__), data_folder, 'bus-bcn.net'))

# Read list of lines for each edge
df = pd.read_pickle(os.path.join(os.path.dirname(__file__), data_folder, 'bus-bcn-lines.pkl'))
lines = {
    (u, v, k): df.loc[(df['source'] == u) & (df['target'] == v), 'lines'].values[0] for u, v, k in G.edges(keys=True)
}

# Set the lines for each edge
nx.set_edge_attributes(G, lines, 'lines')

# Obtain the shortest path using Dijkstra's algorithm
# paths = dict(nx.all_pairs_dijkstra_path(G, weight='weight'))
transhipment_dict = {}
for source in G.nodes:
    for target in G.nodes - source:
        try:
            for path in nx.all_shortest_paths(G, source, target, None, 'dijkstra'):
                previous_lines = lines[(path[0], path[1], 0)]
                current_stop = path[1]
                transhipments_count = 0
                for next_stop in path[2:]:
                    bus_lines = lines[(current_stop, next_stop, 0)]
                    if np.all(bus_lines != previous_lines):
                        transhipments_count += 1
                        previous_lines = bus_lines
                    current_stop = next_stop
                transhipment_dict[(source, target)] = transhipment_dict.get((source, target), [])
                (transhipment_dict[(source, target)]).append(transhipments_count)
                print(f'Shortest path: {len(path)}')
                print(f'Number of transhipments: {transhipments_count}')
            print(transhipment_dict[(source, target)])
        except NetworkXNoPath as e:
            print(e)

pprint(transhipment_dict)
