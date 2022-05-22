import os
from pprint import pprint

import matplotlib.pyplot as plt
import numpy as np

import percolate
import networkx as nx

data_folder = 'data'
G = nx.read_pajek(os.path.join(data_folder, 'bus-bcn.net'))
G = nx.Graph(G)

x_coord = nx.get_node_attributes(G, 'x')
y_coord = nx.get_node_attributes(G, 'y')

coordinates = {n: (x, y_coord[n]) for n, x in x_coord.items()}

edges = list()
fig, axes = plt.subplots(figsize=(10.0, 4.0), ncols=5, nrows=2, squeeze=True)
axes = axes.ravel()
for i, sample_state in enumerate(percolate.sample_states(G, spanning_cluster=False)):
    if i == 10:
        break
    if 'edge' in sample_state:
        edge = sample_state['edge']
        edges.append(edge)
    aux = G.copy()
    aux.remove_edges_from([e for e in G.edges if e not in edges])
    aux.remove_nodes_from(list(nx.isolates(aux)))
    nx.draw(aux, ax=axes[i], width=1, pos=coordinates, node_size=1)
    axes[i].set_title(f'n = {i}')
    pprint(sample_state)
plt.tight_layout()
plt.show()

runs = 2
net_single_runs = [percolate.single_run_arrays(graph=G, spanning_cluster=False) for _ in range(runs)]
# plot
fig, axes = plt.subplots(
    nrows=1, ncols=4, squeeze=True, figsize=(8.0, 6.0)
)
for single_run in net_single_runs:
    axes[0].plot(
        single_run['max_cluster_size'], lw=4, alpha=0.7, rasterized=True
    )
    for k in range(3):
        axes[k + 1].plot(
            single_run['moments'][k], lw=4, alpha=0.7, rasterized=True
        )

    for ax in axes:
        num_edges = net_single_runs[0]['M']
        ax.set_xlim(xmax=1.05 * num_edges)
        ax.set_yticks(np.linspace(0, ax.get_ylim()[1], num=3))

    axes[0].set_yticks([0, 1])

axes[0].set_title(r'largest cluster')
for k in range(3):
    axes[k + 1].set_title(r'$M_{}$'.format(k))

for ax in axes:
    ax.set_xlabel(r'$n$')

plt.tight_layout()
plt.show()

# clear memory
del net_single_runs
