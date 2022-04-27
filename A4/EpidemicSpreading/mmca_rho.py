import os
import networkx as nx
import numpy as np

LINE_CLEAR = "\x1b[2K"

networks_path = os.path.join("A4-networks")
results_path = os.path.join("output", "results")


def mmca(adj_matrix, p0, beta, mu, t_max, t_trans):
    print(f'\rbeta={beta}', end='')
    n_nodes = adj_matrix.shape[0]
    rho = np.empty(t_max)
    p = np.full(n_nodes, p0)
    for i in range(t_max):
        q = np.prod(1 - beta * adj_matrix * p, axis=0)
        p = (1-q) * (1-p) + (1-mu)*p
        rho[i] = np.mean(p)
    return np.mean(rho[t_trans:])


for root, dirs, files in os.walk(networks_path):
    for filename in files:
        net_name, ext = os.path.splitext(filename)
        print(net_name)
        G = nx.read_pajek(os.path.join(root, filename))
        adj_matrix = nx.to_numpy_array(G)
        net_dir = os.path.join(results_path, net_name)
        for subdir in os.listdir(net_dir):
            save_path = os.path.join(net_dir, subdir, "mmcaRho.txt")
            beta = np.loadtxt(os.path.join(net_dir, subdir, "beta.txt"))
            if not os.path.exists(save_path) or np.all(np.isnan(np.loadtxt(save_path))) or len(beta) != len(np.loadtxt(save_path)):
                mu = float(subdir.split("-")[-1])
                print(f'\r{LINE_CLEAR} mu = {mu}')
                n_beta = beta.shape[0]
                rho = np.empty(n_beta)
                for i in range(n_beta):
                    rho[i] = mmca(adj_matrix, 0.2, beta[i], mu, 1000, 900)
                np.savetxt(os.path.join(net_dir, subdir, "mmcaRho.txt"), rho)






