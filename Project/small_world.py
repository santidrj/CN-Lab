import random
import networkx as nx
import numpy as np
import os
import pickle
import matplotlib.pyplot as plt
from networkx import NetworkXNoPath
from pprint import pprint

seed = None
if seed:
    random.seed(seed)


def subset_net(net, lines):
    sub_net = nx.DiGraph(((u, v, e) for u, v, e in net.edges(data=True)
                          if any(map(lambda l: l in e['lines'], lines))))
    return sub_net


def subset_lines(connections, n_lines):
    while True:
        subset = []
        max_iter = 100
        group = list(connections.keys())
        while len(subset) < n_lines and max_iter > 0:
            line = random.choice(group)
            if connections[line]:
                group = connections[line] + [line]
                subset = list(set(subset + random.sample(group, min(len(group), n_lines - len(subset)))))
            max_iter -= 1
        if len(subset) >= n_lines:
            break
    return subset


def mean_path_subnets(net, connections, n_subnets, n_reps, min_lines=10, max_lines=100):
    mean_mean_path = []
    mean_N = []
    for j in range(n_reps):
        print(f"Subset of sub-nets #{j}")
        mean_path = []
        N = []
        step = (max_lines - min_lines) // n_subnets
        n_lines = min_lines
        # i = 0
        for i in range(n_subnets):
            # i += 1
            # print(i)
            while True:
                print(f"Computing subset of {n_lines} lines...")
                lines = subset_lines(connections, n_lines)
                # print("Computing subnet...")
                sub_net = subset_net(net, lines)
                if seed or nx.number_weakly_connected_components(sub_net) == 1:
                    break
            # print("Computing mean path...")
            mean_path.append(nx.average_shortest_path_length(sub_net))
            N.append(sub_net.number_of_nodes())
            n_lines += step
        mean_mean_path.append(mean_path)
        mean_N.append(N)
    print("Done with subnets.")
    mean_mean_path = np.mean(mean_mean_path, axis=0)
    mean_N = np.mean(mean_N, axis=0)
    print("Computing mean path of the whole network...")
    np.append(mean_mean_path, nx.average_shortest_path_length(net))
    np.append(mean_N, net.number_of_nodes())
    return mean_N, mean_mean_path


def plot_mean_path_N(net, connections, out_folder="", load=False, n_reps=100):
    if load:
        f = open(os.path.join(out_folder, 'mean_path_N.pkl'), 'rb')
        mean_path_N = pickle.load(f)
        N, mean_path = list(mean_path_N.keys()), list(mean_path_N.values())
    else:
        if seed:
            n_reps = 1
        N, mean_path = mean_path_subnets(net, connections, 20, min_lines=20, n_reps=n_reps)
        f = open(os.path.join(out_folder, 'mean_path_N.pkl'), 'wb')
        pickle.dump(dict(zip(N, mean_path)), f)
        f.close()

    fit = np.polyfit(np.log10(N), mean_path, 1)
    plt.plot(N, mean_path, 'ko-')
    plt.plot(N, fit[0] * np.log10(N) + fit[1], "k-")
    plt.xscale(u'log')
    plt.xlabel("N")
    plt.ylabel("D(N)")
    # plt.title(f'{seed}')
    plt.savefig(os.path.join(out_folder, 'mean_path_N.png'))
    plt.show()


def plot_hists(net, bins=20, out_folder=""):
    node_degrees = [k[-1] for k in nx.degree(net)]

    fig = plt.figure()
    plt.hist(node_degrees, bins=bins,
             density=True, color='grey', edgecolor='white')
    plt.xlabel("k")
    plt.ylabel("P(k)")
    plt.savefig(os.path.join(out_folder, "PDF.png"))

    fig = plt.figure()
    plt.hist(node_degrees, bins=bins, cumulative=-1,
             density=True, color='grey', edgecolor='white')
    plt.xlabel("k")
    plt.ylabel("P(k)")
    plt.savefig(os.path.join(out_folder, "CCDF.png"))

    fig = plt.figure()
    log_k = np.linspace(np.log10(min(node_degrees)), np.log10(max(node_degrees)), bins)
    n, bins, patches = plt.hist(node_degrees, 10 ** log_k,
                                log=True, density=True, label='empirical', color='grey', edgecolor='white')
    fit = np.polyfit((log_k[1:] + log_k[:-1]) / 2, n, 1)
    #plt.plot(10 ** log_k, (10**fit[1]) * ( (10 ** log_k) ** fit[0] ), 'k-')
    fit = 10 ** fit
    plt.plot(10**log_k, fit[0]*(10**log_k)**(-fit[1]), 'k-')
    plt.xscale(u'log')
    plt.title("PDF")
    plt.xlabel("k")
    plt.ylabel("P(k)")
    plt.savefig(os.path.join(out_folder, "PDF_log.png"))

    fig = plt.figure()
    plt.hist(node_degrees, 10 ** log_k, cumulative=-1,
             log=True, density=True, label='empirical', color='grey', edgecolor='white')
    plt.gca().set_xscale("log")
    plt.title("CCDF")
    plt.xlabel("k")
    plt.ylabel("P(k)")
    plt.savefig(os.path.join(out_folder, "CCDF_log.png"))


def transhipment_and_shortest_path(net, lines, out_folder=""):
    # Obtain the shortest path using Dijkstra's algorithm
    # paths = dict(nx.all_pairs_dijkstra_path(G, weight='weight'))
    transhipment_dict = {}
    path_length_dict = {}
    for source in net.nodes:
        for target in (net.nodes - source):
            try:
                for path in nx.all_shortest_paths(net, source, target, None, 'dijkstra'):
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
                try:
                    path_length_dict[(source, target)] = len(path)
                except NameError:
                    path_length_dict[(source, target)] = np.inf
                print(transhipment_dict[(source, target)])
            except NetworkXNoPath as e:
                print(e)

    f = open(os.path.join(out_folder, 'transhipment_dict.pkl'), 'wb')
    pickle.dump(transhipment_dict, f)
    f.close()
    f = open(os.path.join(out_folder, 'path_length_dict.pkl'), 'wb')
    pickle.dump(path_length_dict, f)
    f.close()

    pprint(transhipment_dict)

# nx.draw(sub_net,
#     nodelist=list(nx.weakly_connected_components(sub_net))[0],
#     node_size=8,
#     width=1,
#     pos=nx.kamada_kawai_layout(sub_net)
# )
# plt.show()


# color_map = []
# for node in sub_net:
#     if node in S[0].nodes():
#         color_map.append('blue')
#     else:
#         color_map.append('green')
#
# nx.draw(sub_net, node_size=5, pos=nx.kamada_kawai_layout(sub_net), nodelist=S[1].nodes())
# plt.show()

# z = []
# for u, v, e in S[1].edges(data=True):
#     z = z + [e['lines']]
