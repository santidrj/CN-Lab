import os

import geopandas


data_folder = 'data'
net_data = geopandas.read_file(os.path.join(data_folder, 'raw', 'parades_linia.json'))
print(f'Dataframe shape: {net_data.shape}')
print(f'Data types\n{net_data.dtypes}')
print(net_data.head())

relevant_columns = ['CODI_PARADA', 'NOM_PARADA', 'NOM_LINIA', 'geometry']

net_data = net_data[relevant_columns]
print(net_data.head())
