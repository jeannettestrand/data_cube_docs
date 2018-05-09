for dataset in `ls -1d ~/glovis/Collection1/LANDSAT8/*/`;
do
  python ~/datacube-core/utils/ls_usgs_prepare.py --output $dataset/metadata.yaml $dataset
  datacube dataset add $dataset/metadata.yaml
done


