import os
import pickle
from itertools import chain

import geopandas
import networkx as nx
from networkx import DiGraph

# TODO: detect automatically lines leading to disconnected components
from pandas import Series

data_folder = "data"
net_data = geopandas.read_file(os.path.join(data_folder, "raw", "parades_linia.json"))
print(f"Dataframe shape: {net_data.shape}\n")
print(f"Data types:\n{net_data.dtypes}\n")
print(net_data.head())

relevant_columns = ["NOM_PARADA", "ORDRE", "NOM_LINIA", "SENTIT", "geometry"]

net_data = net_data[relevant_columns]
net_data.drop_duplicates(inplace=True)
net_data.drop(net_data[net_data["NOM_LINIA"] == "111"].index, inplace=True)
net_data.drop(net_data[net_data["NOM_LINIA"] == "128"].index, inplace=True)
net_data.drop(net_data[net_data["NOM_LINIA"] == "118"].index, inplace=True)

net_data_grouped = (
    net_data.groupby(["NOM_LINIA", "SENTIT"], sort=False)
    .apply(lambda g: g.sort_values(by="ORDRE", ascending=True))
    .reset_index(drop=True)
)
net_data_grouped["PROXIMA_PARADA"] = net_data_grouped.groupby(["NOM_LINIA", "SENTIT"])["NOM_PARADA"].shift(-1)
net_data_grouped.dropna(inplace=True)
weights = net_data_grouped.groupby(["NOM_PARADA", "PROXIMA_PARADA"])["NOM_LINIA"].nunique().reset_index(drop=False)
weights.rename(columns={"NOM_LINIA": "weight"}, inplace=True)

print("\nExample of line with next stop added:")
print(net_data_grouped.loc[net_data_grouped["NOM_LINIA"] == "D20"])

weighted_net_data = net_data_grouped.merge(weights, on=["NOM_PARADA", "PROXIMA_PARADA"])
lines_net_data = (
    weighted_net_data.groupby(["NOM_PARADA", "PROXIMA_PARADA"])["NOM_LINIA"].agg(list).reset_index(name="NOM_LINIA")
)
net = lines_net_data.merge(
    weighted_net_data[["NOM_PARADA", "PROXIMA_PARADA", "weight", "geometry"]],
    on=["NOM_PARADA", "PROXIMA_PARADA"],
    how="left",
)
net.rename(
    columns={"NOM_PARADA": "source", "PROXIMA_PARADA": "target", "NOM_LINIA": "lines", "geometry": "coordinates"},
    inplace=True,
)
net.drop_duplicates(subset=["source", "target"], inplace=True)
# Remove self-loops
net.drop(net[net["source"] == net["target"]].index, inplace=True)
net[["source", "target", "lines"]].to_pickle(os.path.join(data_folder, "bus-bcn-lines.pkl"))
net.to_pickle(os.path.join(data_folder, "bus-bcn.pkl"))

line_names = list(set(chain(*net["lines"].tolist())))
connections = dict.fromkeys(line_names, [])
for stop in net_data_grouped["NOM_PARADA"].unique().tolist():
    lines_in_stop = net_data_grouped["NOM_LINIA"][net_data_grouped["NOM_PARADA"] == stop].unique()
    if len(lines_in_stop) > 1:
        for line in lines_in_stop:
            connections[line] = list(set(connections[line] + lines_in_stop[lines_in_stop != line].tolist()))

f = open(os.path.join(data_folder, "line-connections.pkl"), "wb")
pickle.dump(connections, f)
f.close()

print("\nExample of data with weights and list of lines added:")
print(net.head())
print(net.columns)

G = nx.from_pandas_edgelist(net, edge_attr=["weight", "lines"], create_using=DiGraph)
assert nx.number_of_selfloops(G) == 0

attributes = {}
aux_df = net_data.drop_duplicates(subset='NOM_PARADA').set_index('NOM_PARADA')
for node in G.nodes:
    pos = aux_df.loc[node, 'geometry']
    if isinstance(pos, Series):
        pos = pos[0]
    attributes[node] = {"x": pos.x, "y": pos.y}
nx.set_node_attributes(G, attributes)

nx.write_pajek(G, os.path.join(data_folder, "bus-bcn.net"))
