EXTRACT_TO=~/glovis/Collection1/LANDSAT8

for a in `ls -1 *.tar.gz`;
do
  mkdir $EXTRACT_TO/${a::-7};
  tar -zxvf $a -C $EXTRACT_TO/${a::-7};
done 
