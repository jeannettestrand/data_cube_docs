#
# This is an experimental script to calculate the min/max values
# of a given set of bands. Must be used on netCDF files created
# by Open Data Cube
#
# Author: Tyler J.B. Hall <tyler@ionise.org>
#
import os
import gdal
import numpy as np

search_path = '.'
bands = ['red', 'green', 'blue']
no_data = -9999

directory = os.path.normpath(os.path.join(os.getcwd(), search_path))
min_values = {} 
max_values = {} 
for x in bands:
	min_values[x] = ''
	max_values[x] = ''

for file in os.listdir(directory):
	if file.endswith(".nc"):
		#print(os.path.join(directory + "/", file))
		for band in bands:
			ds = gdal.Open('netCDF:' + os.path.join(directory, file) + ':' + band)
			data = ds.GetRasterBand(1).ReadAsArray(0, 0, ds.RasterXSize, ds.RasterYSize)
			data_min = np.amin(data[data != no_data])
			data_max = np.amax(data[data != no_data])
			min_values[band] = min_values[band] if min_values[band] else data_min
			max_values[band] = max_values[band] if max_values[band] else data_max

			if data_min < min_values[band]: min_values[band] = data_min
			if data_max > max_values[band]: max_values[band] = data_max

for band in bands:
	print('{}: min = {}, max = {}'.format(band, min_values[band], max_values[band]))
