#!/bin/bash

###############################################
#    Datacube Installation with JupyterHub    #
###############################################
#
# WARNING: This script can be extremely dangerous and WILL modify
#          your system settings.
#
# Install datacube to /local/datacube (using miniconda)
# Generate connection configuration file
# Allow a JupyterHub runner running JupyterHub through sudospawner.
# Create a system service jupyterhub.service

OUTPUT="/dev/null"
CONDAQUIET="-q"
CURLQUIET="-s"
PIPQUIET="-qqq"
HASDB=false
HUBUSERNAME=""
NULLOUTPUT="/dev/null"

for i in "$@"
do
case $i in
  -h|--help)
  echo "Usage: $0 [-h|--help] [-v|--verbose]"
  echo "  -h|--help           display this help message"
  echo "  -v|--verbose        display all installation messages"
  exit 0
  ;;
  -v|--verbose)
  OUTPUT="/dev/stdout"
  CURLQUIET=""
  CONDAQUIET=""
  PIPQUIET=""
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
echo "###################################"
echo "#    Database Connection Info     #"
echo "###################################"
echo "Datacube requires database to operate. "
echo "You can use an existing database or create a database later."

while true
do
echo
echo -n "--> Have you installed database server? (y)es/(n)o "
read ANSWER
case $ANSWER in
  no|No|NO|n|N)
  echo "Datacube configuration file will not be generated"
  HASDB=false
  break
  ;;
  yes|Yes|YES|y|Y)
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
echo
echo "Please enter the IP address of database server"
echo -n "--> Enter database IP address: "
read DBADD
if [[ -n $DBADD ]]
then
  break
fi
echo "Error: Empty database address! Please try again."
done

while $HASDB
do
echo
echo "Please enter the database name"
echo -n "--> Enter database name: "
read DBNAME
if [[ -n $DBNAME ]]
then
  break
fi
echo "Error: Empty database name! Please try again."
done

while $HASDB
do
echo
echo "Please enter the username for database connection"
echo -n "--> Enter username: "
read USERNAME
if [[ -n $USERNAME ]]
then
  break
fi
echo "Error: Empty username! Please try again."
done

while $HASDB
do
echo
echo "Please enter the password for database connection"
echo -n "--> Enter password: "
read -s PASSWORD
if [[ -n $PASSWORD ]]
then
  break
fi
echo "Error: Empty password! Please try again."
done

echo
echo "###################################"
echo "#     JupyterHub runner info      #"
echo "###################################"
echo "A runner account will be created to avoid running JupyterHub as root."
echo "Warning: The account will have read access to /etc/shadow"
echo "A JupyterHub runner will be created with no login restriction."

while true
do
echo
echo "Please enter the username for JupyterHub runner"
echo -n "--> Enter runner username for JupyterHub: "
read HUBUSERNAME
if [[ -n $HUBUSERNAME ]]
then
  break
fi
echo "Error: Empty username! Please try again."
done

# Request sudo permission to complete sudo jobs
echo
echo "@ Requesting super user permission"
sudo echo

echo
echo "Now setting up datacube, this may take some time..."

echo
echo "Ensuring users and groups..."

# Check if JupyterHub runner user exists already
USERCHECK="$(sudo cat /etc/passwd | grep $HUBUSERNAME)"
if [[ -z $USERCHECK ]]
then
  sudo useradd $HUBUSERNAME -s /sbin/nologin
else
  echo "Notice: User $HUBUSERNAME exists."
fi

# Check if shadow group exists already
SHADOWGROUPCHECK="$(sudo cat /etc/group | grep ^shadow)"
if [[ -z $SHADOWGROUPCHECK ]]
then
  sudo groupadd shadow
fi

# Grant shadow group read access on /etc/shadow file for PAM local auth
sudo chgrp shadow /etc/shadow
sudo chmod g+r /etc/shadow

# Add JupyterHub runner to shadow group
sudo usermod -a -G shadow $HUBUSERNAME

# Check if jupyteruser group exists already
JUPYTERUSERGROUPCHECK="$(sudo cat /etc/group | grep ^jupyteruser)"
if [[ -z $JUPYTERUSERGROUPCHECK ]]
then
  sudo groupadd jupyteruser
fi

# Allow JupyterHub to run sudo spawner on behalf of jupyteruser group
echo "" | sudo tee -a /etc/sudoers >> $NULLOUTPUT
echo "# the command the Hub can run on behalf of the above users without needing a password" | sudo tee -a /etc/sudoers >> $NULLOUTPUT
echo "# the exact path may differ, depending on how sudospawner was installed" | sudo tee -a /etc/sudoers >> $NULLOUTPUT
echo "Cmnd_Alias JUPYTER_CMD = /local/datacube/miniconda3/envs/cubeenv/bin/sudospawner" | sudo tee -a /etc/sudoers >> $NULLOUTPUT
echo "" | sudo tee -a /etc/sudoers >> $NULLOUTPUT
echo "# actually give the Hub user permission to run the above command on behalf" | sudo tee -a /etc/sudoers >> $NULLOUTPUT
echo "# of the jupyteruser group without prompting for a password" | sudo tee -a /etc/sudoers >> $NULLOUTPUT
echo "$HUBUSERNAME ALL=(%jupyteruser) NOPASSWD:JUPYTER_CMD" | sudo tee -a /etc/sudoers >> $NULLOUTPUT

# Create a system service for JupyterHub
SERVICEFILE=/lib/systemd/system/jupyterhub.service
CHECKSERVICEFILE="$(ls /lib/systemd/system | grep jupyterhub)"
if [[ -z $CHECKSERVICEFILE ]]
then
  sudo touch $SERVICEFILE
  echo "[Unit]" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "Description=Jupyterhub" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "After=network-online.target" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "[Service]" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "User=$HUBUSERNAME" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "WorkingDirectory=/local/datacube/jupyterhub" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "Environment=PATH=/local/datacube/miniconda3/envs/cubeenv/bin:$PATH" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "ExecStartPre=/bin/bash /local/datacube/miniconda3/envs/cubeenv/etc/conda/activate.d/gdal-activate.sh" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "ExecStartPre=/bin/bash /local/datacube/miniconda3/envs/cubeenv/etc/conda/activate.d/proj4-activate.sh" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "ExecStart=/local/datacube/miniconda3/envs/cubeenv/bin/jupyterhub" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "KillSignal=SIGINT" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "[Install]" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
  echo "WantedBy=multi-user.target" | sudo tee -a $SERVICEFILE >> $NULLOUTPUT
else
  echo "Notice: File jupyterhub.service exists. Please overwrite this file manually"
fi

# Init /local/datacube sub-directory structure
sudo mkdir /local
sudo mkdir /local/datacube
sudo mkdir /local/datacube/jupyterhub
sudo chown $USER:$USER /local/datacube
sudo chown $HUBUSERNAME:$HUBUSERNAME /local/datacube/jupyterhub

sudo cp jupyterhub_config.py /local/datacube/jupyterhub
sudo chown $HUBUSERNAME:$HUBUSERNAME /local/datacube/jupyterhub/jupyterhub_config.py

echo "Installing datacube environment. This may take some time..."

# Install required packages if using minimal installation of CentOS
sudo yum install gcc bzip2 -y >> $OUTPUT

# Conda used for package, dependency and environment management for any language, cross-platform
cd /local/datacube
curl $CURLQUIET -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh >> $OUTPUT
sh Miniconda3-latest-Linux-x86_64.sh -b -p /local/datacube/miniconda3 >> $OUTPUT
sudo ln -s /local/datacube/miniconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh
source $HOME/.bashrc
conda update -n base conda -y $CONDAQUIET >> $OUTPUT
conda config --append channels conda-forge >> $OUTPUT
conda create --name cubeenv python=3.6 datacube -y $CONDAQUIET >> $OUTPUT
conda activate cubeenv
conda install cython matplotlib scipy jupyter jupyterhub -y $CONDAQUIET >> $OUTPUT
pip $PIPQUIET install sudospawner >> $OUTPUT
conda deactivate

# Generate configuration file if connection info is provided
if [[ $HASDB = true ]]
then
  echo "Generating configuration file..."
  DATACUBECONFIGFILE="$HOME/.datacube.conf"
  echo "[datacube]" > $DATACUBECONFIGFILE
  echo "db_database: $DBNAME" >> $DATACUBECONFIGFILE
  echo "db_hostname: $DBADD" >> $DATACUBECONFIGFILE
  echo "db_username: $USERNAME" >> $DATACUBECONFIGFILE
  echo "db_password: $PASSWORD" >> $DATACUBECONFIGFILE
fi

# Completion prompt
echo
echo "Datacube has been installed."
echo "You have enabled user $HUBUSERNAME running JupyterHub."
echo "To start JupyterHub, use command: "
echo "  sudo systemctl start jupyterhub"
echo ""
echo "To add a new jupyter notebook user, use command: "
echo "  sudo adduser -G jupyteruser (newuser) -s /sbin/nologin"

# Refresh the user's bash
exec bash
