import os

import geopandas
import networkx as nx
from networkx import DiGraph

data_folder = 'data'
net_data = geopandas.read_file(os.path.join(data_folder, 'raw', 'parades_linia.json'))
print(f'Dataframe shape: {net_data.shape}\n')
print(f'Data types:\n{net_data.dtypes}\n')
print(net_data.head())

relevant_columns = ['NOM_PARADA', 'ORDRE', 'NOM_LINIA', 'SENTIT', 'geometry']

net_data = net_data[relevant_columns]
net_data.drop_duplicates(inplace=True)

net_data_grouped = (
    net_data.groupby(['NOM_LINIA', 'SENTIT'], sort=False)
    .apply(lambda g: g.sort_values(by='ORDRE', ascending=True))
    .reset_index(drop=True)
)
net_data_grouped['PROXIMA_PARADA'] = net_data_grouped.groupby(['NOM_LINIA', 'SENTIT'])['NOM_PARADA'].shift(-1)
net_data_grouped.dropna(inplace=True)
weights = net_data_grouped.groupby(['NOM_PARADA', 'PROXIMA_PARADA'])['NOM_LINIA'].nunique().reset_index(drop=False)
weights.rename(columns={'NOM_LINIA': 'weight'}, inplace=True)

print('\nExample of line with next stop added:')
print(net_data_grouped.loc[net_data_grouped['NOM_LINIA'] == 'D20'])

weighted_net_data = net_data_grouped.merge(weights, on=['NOM_PARADA', 'PROXIMA_PARADA'])
lines_net_data = (
    weighted_net_data.groupby(['NOM_PARADA', 'PROXIMA_PARADA'])['NOM_LINIA'].agg(list).reset_index(name='NOM_LINIA')
)
net = lines_net_data.merge(
    weighted_net_data[['NOM_PARADA', 'PROXIMA_PARADA', 'weight', 'geometry']],
    on=['NOM_PARADA', 'PROXIMA_PARADA'],
    how='left',
)
net.rename(
    columns={'NOM_PARADA': 'source', 'PROXIMA_PARADA': 'target', 'NOM_LINIA': 'lines', 'geometry': 'coordinates'},
    inplace=True,
)
net.drop_duplicates(subset=['source', 'target'], inplace=True)
# Remove self-loops
net.drop(net[net['source'] == net['target']].index, inplace=True)
net.to_pickle(os.path.join(data_folder, 'bus-bcn.pkl'))

print('\nExample of data with weights and list of lines added:')
print(net.head())
print(net.columns)

G = nx.from_pandas_edgelist(net, edge_attr=['weight', 'lines'], create_using=DiGraph)

attributes = {n: {'x': c.x, 'y': c.y} for n, c in zip(G.nodes, net['coordinates'])}
nx.set_node_attributes(G, attributes)

nx.write_pajek(G, os.path.join(data_folder, 'bus-bcn.net'))
