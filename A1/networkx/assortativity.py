# install networkx: pip install networkx[default]
import networkx as nx

g_nan = nx.read_pajek("A1/A1-networks/toy/circle9.net")
r_nan = nx.degree_assortativity_coefficient(g_nan)
print("Circle9 network assortativity: {}".format(r_nan))

g = nx.read_pajek("A1/A1-networks/toy/wheel.net")
r = nx.degree_assortativity_coefficient(g)
print("Wheel network assortativity: {}".format(r))
