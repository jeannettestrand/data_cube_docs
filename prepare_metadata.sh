#DATA_DIR=~/glovis/Collection1/LANDSAT8
DATA_DIR=~/google/LANDSAT8
for dataset in $DATA_DIR/*/;
do
  python ~/datacube-core/utils/ls_usgs_prepare.py --output $dataset/metadata.yaml $dataset
  datacube dataset add $dataset/metadata.yaml
done


