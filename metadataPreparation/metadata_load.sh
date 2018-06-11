set in `ls -1d`;
do
  python ~/datacube-core/utils/ls_usgs_prepare.py --output $dataset/metadata.yaml $dataset
  datacube dataset add $dataset/metadata.yaml
done


