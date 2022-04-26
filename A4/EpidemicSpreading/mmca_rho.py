import os
import networkx as nx
import numpy as np

networks_path = os.path.join("A4-networks")
results_path = os.path.join("output", "results")


def mmca(adj_matrix, p0, beta, mu, eps, t_max, t_trans):
    n_nodes = adj_matrix.shape[0]
    rho = np.empty(t_max)
    eps_arr = np.full(n_nodes, eps)
    for i in range(t_max):
        print(f'\rt={i}/{t_max}', end='')
        converged = False
        p = np.full(n_nodes, p0)
        while not converged:
            q = np.array([np.prod(1 - beta * adj_matrix[i] * p) for i in range(n_nodes)])
            old_p = p
            p = (1-q) * (1-p) + (1-mu)*p
            converged = sum(abs(p-old_p) > eps_arr) == 0
        rho[i] = (1./n_nodes) * sum(p)
    return np.mean(rho[t_trans:])


for root, dirs, files in os.walk(networks_path):
    for filename in files:
        net_name, ext = os.path.splitext(filename)
        if net_name == "BA-500-5-3-6" and ext == ".net":
            print(net_name)
            G = nx.read_pajek(os.path.join(root, filename))
            adj_matrix = nx.to_numpy_array(G)
            net_dir = os.path.join(results_path, net_name)
            for subdir in os.listdir(net_dir):
                mu = float(subdir.split("-")[-1])
                print(mu)
                beta = np.loadtxt(os.path.join(net_dir, subdir, "beta.txt"))
                n_beta = beta.shape[0]
                rho = np.zeros(n_beta)
                for i in range(n_beta):
                    rho[i] = mmca(adj_matrix, 0.2, beta[i], mu, 0.005, 1000, 900)
                np.savetxt(os.path.join(net_dir, "mmcaRho.txt"), rho)






