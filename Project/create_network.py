import os

import geopandas


data_folder = 'data'
net_data = geopandas.read_file(os.path.join(data_folder, 'raw', 'parades_linia.json'))
print(f'Dataframe shape: {net_data.shape}\n')
print(f'Data types:\n{net_data.dtypes}\n')
print(net_data.head())

relevant_columns = ['NOM_PARADA', 'ORDRE', 'NOM_LINIA', 'SENTIT', 'geometry']

net_data = net_data[relevant_columns]

net_data_grouped = net_data.groupby(['NOM_LINIA', 'SENTIT'], sort=False).apply(lambda g: g.sort_values(by='ORDRE', ascending=True)).reset_index(drop=True)
net_data_grouped['PROXIMA_PARADA'] = net_data_grouped.groupby(['NOM_LINIA', 'SENTIT'])['NOM_PARADA'].shift(-1)
net_data_grouped.dropna(inplace=True)
weights = net_data_grouped.groupby(['NOM_PARADA', 'PROXIMA_PARADA'])['NOM_LINIA'].nunique().reset_index(drop=False)
weights.rename(columns={'NOM_LINIA': 'weight'}, inplace=True)

print('\nExample of line with next stop added:')
print(net_data_grouped.loc[net_data_grouped['NOM_LINIA'] == 'D20'])

weighted_net_data = net_data_grouped.merge(weights, on=['NOM_PARADA', 'PROXIMA_PARADA'])
print('\nExample of data with weights added:')
print(weighted_net_data.head())

