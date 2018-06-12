#!/bin/sh

for dataset in `ls -1d`;
do
  python ~/data/datacube/data_cube_docs/ls_usgs_prepare.py --output /data/datacube/in/landsat/$dataset/metadata.yaml /data/datacube/in/landsat/$dataset
  datacube dataset add /data/datacube/in/landsat/$dataset/metadata.yaml
done
