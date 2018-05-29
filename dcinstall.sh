#!/bin/bash

VERBOSE=false
OUTPUT="$HOME/datacube_install.log"
CONDAQUIET=""
GITQUIET=""
HASDB=false

for i in "$@"
do
case $i in
  -h|--help)
  echo "Usage: $0 [-h|--help] [-v|--verbose] [--no-progress-bar]"
  echo "  -h|--help           display this help message"
  echo "  -v|--verbose        display all installation messages"
  echo "  --no-progress-bar   no progress bar for datacube environment installation"
  exit 0
  ;;
  --no-progress-bar)
  CONDAQUIET="-q"
  GITQUIET="-q"
  ;;
  -v|--verbose)
  VERBOSE=true
  OUTPUT="/dev/stdout"
  ;;
  *)
  echo unknown option $i
  ;;
esac
done

if [[ $VERBOSE = false ]]
then
    echo "Datacube Installation Log" > $OUTPUT
fi

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@      Welcome to Datacube      @@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo
echo "Before installing datacube, you must install database server first."
while true
do
echo -n "--> Have you installed database server? (y)es/(n)o "
read ANSWER
case $ANSWER in
  no|No|NO|n|N)
  echo "Please generate datacube configuration file yourself"
  HASDB=false
  break
  ;;
  yes|Yes|YES|y|Y)
  echo "Please provide your database server information to proceed"
  HASDB=true
  break
  ;;
  *)
  echo "Invalid answer."
  ;;
esac
done

while $HASDB
do
echo "Please enter the IP address of database server"
echo -n "--> Enter database address: "
read DBADD
if [[ $DBADD != "" ]]
then
  break
fi
echo "Cannot accept empty database address!"
done

while $HASDB
do
echo "Please enter the username for database"
echo -n "--> Enter username: "
read USERNAME
if [[ $USERNAME != "" ]]
then
  break
fi
echo "Cannot accept empty username!"
done

while $HASDB
do
echo "Please enter the password for database"
echo -n "--> Enter password: "
read -s PASSWORD
if [[ $PASSWORD != "" ]]
then
  break
fi
echo "Cannot accept empty password!"
done

echo
echo "Now setting up datacube, this may take some time..."
echo

echo @ Requesting super user permission
sudo echo

# Install extra packages if using minimal installation of CentOS
sudo yum install gcc bzip2 -y >> $OUTPUT

# Conda used for package, dependency and environment management for any language, cross-platform
echo Installing datacube environment. This may take some time...
# Make /local/datacube sub-directory
sudo mkdir /local
sudo mkdir /local/datacube
cd /local/datacube
sudo chown $USER:$USER .
curl -s -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh >> $OUTPUT
sh Miniconda3-latest-Linux-x86_64.sh -b -p /local/datacube/miniconda3 >> $OUTPUT
sudo ln -s /local/datacube/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh
source $HOME/.bashrc
conda update -n base conda -y $CONDAQUIET >> $OUTPUT
conda config --add channels conda-forge >> $OUTPUT
conda create --name cubeenv python=3.6 datacube -y $CONDAQUIET >> $OUTPUT

if [[ $HASDB = true ]]
then
  echo "Generating configuration File..."
  DATACUBECONFIGFILE="$HOME/.datacube.conf"
  echo "[datacube]" > $DATACUBECONFIGFILE
  echo "db_database: datacube" >> $DATACUBECONFIGFILE
  echo "db_hostname: $DBADD" >> $DATACUBECONFIGFILE
  echo "db_username: $USERNAME" >> $DATACUBECONFIGFILE
  echo "db_password: $PASSWORD" >> $DATACUBECONFIGFILE
fi

echo "Installing datacube-core..."
conda activate cubeenv
conda install cython -y $CONDAQUIET >> $OUTPUT
conda install jupyter jupyterhub -y $CONDAQUIET >> $OUTPUT

echo
echo "Datacube has been installed."
if [[ $VERBOSE = false ]]
then
  echo "Log file of this installation has been saved to $OUTPUT."
fi

# Refresh the user's bash
exec bash
