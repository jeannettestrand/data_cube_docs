#!/bin/bash

ENV="production"
VERBOSE=false
OUTPUT="datacube_install.log"
CONDAQUIET=""

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
echo @ Requesting super user permission
sudo echo

# Switch to user's home directory
cd

echo Updating local system...
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
curl -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh >> $OUTPUT
sh Miniconda3-latest-Linux-x86_64.sh -b >> $OUTPUT
echo export PATH=\"$PWD/miniconda3/bin:\$PATH\" >> ~/.bashrc
source ~/.bashrc
conda update -n base conda -y $CONDAQUIET >> $OUTPUT
conda config --add channels conda-forge >> $OUTPUT
conda create --name cubeenv python=3.6 datacube -y $CONDAQUIET >> $OUTPUT

# Matplotlib provides both a very quick way to visualize data from Python
# Scipi is a Python-based ecosystem of open-source software for mathematics, science, and engineering
# Jupyter Notebook is an open-source web application that allows you to create and share documents
# that contain live code, equations, visualizations and narrative text
echo Installing development packages. This may take some time...
if [[ $ENV = 'development' ]]
then
    conda install jupyter matplotlib scipy -y $CONDAQUIET >> $OUTPUT
fi

echo
echo Datacube has been installed. Log file has been saved to $PWD/datacube_install.log
