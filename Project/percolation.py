import os
from pprint import pprint

import matplotlib.pyplot as plt
import networkx as nx
import numpy as np
import percolate

data_folder = 'data'
G = nx.read_pajek(os.path.join(data_folder, 'bus-bcn.net'))
G = nx.Graph(G)

x_coord = nx.get_node_attributes(G, 'x')
y_coord = nx.get_node_attributes(G, 'y')

coordinates = {n: (x, y_coord[n]) for n, x in x_coord.items()}
G.add_nodes_from(['Aux0', 'Aux1'], span=0)
G.add_nodes_from(['Aux2', 'Aux3', 'Aux4'], span=1)
G.add_edges_from(
    [
        ('Aux0', 'Mercabarna'),
        ('Aux1', 'Pg  Zona Franca - Mineria'),
        ('Aux2', 'Gran Via - Marina'),
        ('Aux3', 'Metro Tetuan'),
        ('Aux4', 'Panamà - Abadessa Olzet'),
    ]
)
coordinates['Aux0'] = coordinates['Mercabarna']
coordinates['Aux1'] = coordinates['Pg  Zona Franca - Mineria']
coordinates['Aux2'] = coordinates['Gran Via - Marina']
coordinates['Aux3'] = coordinates['Metro Tetuan']
coordinates['Aux4'] = coordinates['Panamà - Abadessa Olzet']

edges = list()
fig, axes = plt.subplots(figsize=(8.0, 8.0), ncols=2, nrows=2, squeeze=True)
axes = axes.ravel()
for i, sample_state in enumerate(percolate.sample_states(G, spanning_cluster=True)):
    if i > 100:
        break
    if 'edge' in sample_state:
        edge = sample_state['edge']
        edges.append(edge)

        if i > 0 and i % 25 == 0:
            aux = G.copy()
            aux.remove_edges_from([e for e in G.edges if e not in edges])
            aux.remove_nodes_from(list(nx.isolates(aux)))
            nx.draw_networkx_nodes(
                G, nodelist=G.nodes - aux.nodes, ax=axes[i // 25 - 1], pos=coordinates, node_size=1, alpha=0.4
            )
            nx.draw(aux, ax=axes[i // 25 - 1], width=1, pos=coordinates, node_size=1)
            axes[i // 25 - 1].set_title(f'n = {i}')
            pprint(sample_state)
plt.tight_layout()
plt.show()
plt.close()

# Single run statistics
runs = 2
# net_single_runs = [percolate.single_run_arrays(graph=G, spanning_cluster=False) for _ in range(runs)]
# plot
# fig, axes = plt.subplots(
#     nrows=1, ncols=4, squeeze=True, figsize=(12.0, 6.0)
# )
# for single_run in net_single_runs:
#     axes[0].plot(
#         single_run['max_cluster_size'], lw=2, alpha=0.7
#     )
#     for k in range(3):
#         axes[k + 1].plot(
#             single_run['moments'][k], lw=2, alpha=0.7
#         )
#
# for ax in axes:
#     num_edges = net_single_runs[0]['M']
#     ax.set_xlim(xmax=1.05 * num_edges)
#     ax.set_yticks(np.linspace(0, ax.get_ylim()[1], num=3))
#
#
# axes[0].set_title(r'largest cluster')
# for k in range(3):
#     axes[k + 1].set_title(r'$M_{}$'.format(k))
#
# for ax in axes:
#     ax.set_xlabel(r'$n$')
#
# plt.tight_layout()
# plt.show()

# clear memory
# del net_single_runs

# Microcanonical ensemble averages
net_microcanonical_averages = percolate.microcanonical_averages(G, runs, spanning_cluster=True)
net_microcanonical_averages_array = percolate.microcanonical_averages_arrays(net_microcanonical_averages)

fig, axes = plt.subplots(nrows=1, ncols=2, squeeze=True, figsize=(12.0, 6.0))

(line,) = axes[0].plot(
    np.arange(net_microcanonical_averages_array['M'] + 1),
    net_microcanonical_averages_array['max_cluster_size'],
)
axes[0].fill_between(
    np.arange(net_microcanonical_averages_array['M'] + 1),
    net_microcanonical_averages_array['max_cluster_size_ci'].T[1],
    net_microcanonical_averages_array['max_cluster_size_ci'].T[0],
    facecolor=line.get_color(),
    alpha=0.5,
)

axes[1].plot(
    np.arange(net_microcanonical_averages_array['M'] + 1),
    net_microcanonical_averages_array['moments'][2],
)
axes[1].fill_between(
    np.arange(net_microcanonical_averages_array['M'] + 1),
    net_microcanonical_averages_array['moments_ci'][2].T[1],
    net_microcanonical_averages_array['moments_ci'][2].T[0],
    facecolor=line.get_color(),
    alpha=0.5,
)

axes[0].set_ylim(ymax=1.0)
axes[1].set_ylim(ymin=0.0)

for ax in axes:
    num_edges = net_microcanonical_averages_array['M']
    ax.set_xlim(xmax=1.05 * num_edges)
    ax.set_yticks(np.linspace(0, ax.get_ylim()[1], num=3))

axes[0].set_title(r'percolation strength')
axes[1].set_title(r'$\langle M_2 \rangle$')

for ax in axes:
    ax.set_xlabel(r'$n$')

plt.tight_layout()
plt.show()
plt.close()

# Canonical ensemble averages
# occupation probabilities
net_ps_arrays = [np.linspace(1.0 - x, 1.0, num=100) for x in [1.0, 0.5]]
net_stats = [percolate.canonical_averages(ps, net_microcanonical_averages_array) for ps in net_ps_arrays]
# plot
fig, axes = plt.subplots(nrows=len(net_ps_arrays), ncols=3, squeeze=True, figsize=(8.0, 4.5))
for ps_index, ps in enumerate(net_ps_arrays):
    my_stats = net_stats[ps_index]

    (line,) = axes[ps_index, 0].plot(
        ps,
        my_stats['max_cluster_size'],
    )
    axes[ps_index, 0].fill_between(
        ps,
        my_stats['max_cluster_size_ci'].T[1],
        my_stats['max_cluster_size_ci'].T[0],
        facecolor=line.get_color(),
        alpha=0.5,
    )

    axes[ps_index, 1].plot(
        ps,
        my_stats['moments'][2],
    )
    axes[ps_index, 1].fill_between(
        ps,
        my_stats['moments_ci'][2].T[1],
        my_stats['moments_ci'][2].T[0],
        facecolor=line.get_color(),
        alpha=0.5,
    )

    axes[ps_index, 2].semilogy(
        ps,
        my_stats['moments'][2],
    )
    axes[ps_index, 2].fill_between(
        ps,
        np.where(my_stats['moments_ci'][2].T[1] > 0.0, my_stats['moments_ci'][2].T[1], 0.01),
        np.where(my_stats['moments_ci'][2].T[0] > 0.0, my_stats['moments_ci'][2].T[0], 0.01),
        facecolor=line.get_color(),
        alpha=0.5,
    )

    axes[ps_index, 0].set_ylim(ymin=0.0, ymax=1.0)
    axes[ps_index, 1].set_ylim(ymin=0.0)
    axes[ps_index, 2].set_ylim(ymin=0.5)

    for ax in axes[ps_index, :]:
        ax.set_xlim(xmin=np.min(ps), xmax=np.max(ps) + (np.max(ps) - np.min(ps)) * 0.05)
        ax.set_xticks(np.linspace(np.min(ps), np.max(ps), num=3))

    for ax in axes[ps_index, :-1]:
        ax.set_yticks(np.linspace(0, ax.get_ylim()[1], num=3))

axes[0, 0].set_title(r'perc. strength')
axes[0, 1].set_title(r'$\langle M_2 \rangle$')
axes[0, 2].set_title(r'$\langle M_2 \rangle$')

for ax in axes[-1, :]:
    ax.set_xlabel(r'$\phi$')

plt.tight_layout()
plt.show()
