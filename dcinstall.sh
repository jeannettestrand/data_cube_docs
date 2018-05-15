#!/bin/bash

ENV="production"
VERBOSE=false
OUTPUT="$HOME/datacube_install.log"
CONDAQUIET=""
GITQUIET=""

echo "Datacube Installation Log" > ~/datacube_install.log

for i in "$@"
do
case $i in
    -d|--dev)
    ENV="development"
    ;;
    -h|--help)
    echo "Usage: $0 [-d|--dev] [-h|--help] [-v|--verbose] [--no-progress-bar]"
    echo "  -d|--dev            install development packages"
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
    echo "Please install database server first!"
    echo "You may use dbinstall.sh to install database system."
    exit 0
    ;;
    yes|Yes|YES|y|Y)
    echo "Please provide your database server information to proceed"
    break
    ;;
    *)
    echo "Invalid answer."
    ;;
esac
done

while true
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

while true
do
echo "Please enter the username for database"
echo -n "--> Enter new username: "
read USERNAME
if [[ $USERNAME != "" ]]
then
    break
fi
echo "Cannot accept empty username!"
done

while true
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
echo "Thank you! Now setting up datacube, this may take some time..."
echo

# Maintain sudo permission and ensure it will not timeout
# Revert the timeout settings at the end of the script
echo @ Requesting super user permission
sudo sed -i "s/Defaults    env_reset/Defaults    env_reset,timestamp_timeout=-1/g" /etc/sudoers
sudo echo

# Switch to user's home directory
cd

echo Updating local system...
sudo yum install -y deltarpm >> $OUTPUT
sudo yum update -y >> $OUTPUT

# Add IUS (Inline With Upstream) 3rd party repository for Python 3.6
echo Installing python 3.6...
sudo yum install https://centos7.iuscommunity.org/ius-release.rpm -y >> $OUTPUT
sudo yum install python36u python36u-pip python36u-devel -y >> $OUTPUT

# Install extra packages if using minimal installation of CentOS
sudo yum install gcc bzip2 -y >> $OUTPUT

# Install Python packages using pip
# Because of $PATH interactions with sudo, may need to use /usr/local/bin/pip3.6
sudo pip3.6 install pip --upgrade >> $OUTPUT
sudo pip3.6 install pycosat pyyaml requests >> $OUTPUT

# Conda used for package, dependency and environment management for any language, cross-platform
echo Installing datacube environment. This may take some time...
curl -s -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh >> $OUTPUT
sh Miniconda3-latest-Linux-x86_64.sh -b >> $OUTPUT
sudo ln -s $HOME/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh
source $HOME/.bashrc
conda update -n base conda -y $CONDAQUIET >> $OUTPUT
conda config --add channels conda-forge >> $OUTPUT
conda create --name cubeenv python=3.6 datacube -y $CONDAQUIET >> $OUTPUT

echo "Generating configuration File..."
DATACUBECONFIGFILE="$HOME/.datacube.conf"
echo "[datacube]" >> $DATACUBECONFIGFILE
echo "db_database: datacube" >> $DATACUBECONFIGFILE
echo "db_hostname: $DBADD" >> $DATACUBECONFIGFILE
echo "db_username: $USERNAME" >> $DATACUBECONFIGFILE
echo "db_password: $PASSWORD" >> $DATACUBECONFIGFILE

echo "Installing datacube-core..."
conda activate cubeenv
conda install cython -y $CONDAQUIET >> $OUTPUT
datacube -v -v -v system init >> $OUTPUT

sudo yum install git -y >> $OUTPUT
git clone $GITQUIET https://github.com/opendatacube/datacube-core >> $OUTPUT
cd datacube-core
git checkout $GITQUIET develop >> $OUTPUT

# Matplotlib provides both a very quick way to visualize data from Python
# Scipi is a Python-based ecosystem of open-source software for mathematics, science, and engineering
# Jupyter Notebook is an open-source web application that allows you to create and share documents
# that contain live code, equations, visualizations and narrative text
echo "Installing development packages. This may take some time..."
if [[ $ENV = 'development' ]]
then
    conda install jupyter matplotlib scipy -y $CONDAQUIET >> $OUTPUT
fi

echo
echo "Datacube has been installed."
if [[ $VERBOSE = false ]]
then
    echo "Log file of this installation has been saved to $OUTPUT."
fi

# Revert sudo timeout settings
sudo sed -i "s/Defaults    env_reset,timestamp_timeout=-1/Defaults    env_reset/g" /etc/sudoers

# Refresh the user's bash
exec bash
