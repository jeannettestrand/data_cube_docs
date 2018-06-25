#!/bin/bash


for set in `ls -1 $1`;
do
  
  echo "Generating Metadata Document for $set"
  python /data/datacube/docs/metadataPreparation/ls_usgs_prepare.py --output $1/$set/metadata.yaml $1/$set
  
  echo "Indexing $set"
  datacube dataset add $1/$set/metadata.yaml
done


