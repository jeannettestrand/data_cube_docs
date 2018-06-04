#!/bin/bash

##############################
#   JupyterHub sudo-less     #
##############################
#
# WARNING: This script can be extremely dangerous and WILL modify
#          your system settings. DO NOT proceed unless you have
#          full understanding on what this is doing.
#
# This script will allow a specified user running JupyterHub
# without using sudo.

USERNAME=""
OUTPUT="/dev/null"

echo "@ Requesting super user permission"
sudo echo

while true
do
echo "Please enter the username for jupyterhub runner"
echo -n "--> Enter username: "
read USERNAME
if [[ -n $USERNAME ]]
then
  break
fi
echo "Cannot accept empty username!"
done

# Check if the user exists already
USERCHECK="$(sudo cat /etc/passwd | grep $USERNAME)"
if [[ -z $USERCHECK ]]
then
  sudo useradd $USERNAME
fi

# Check if shadow group exists already
SHADOWGROUPCHECK="$(sudo cat /etc/group | grep ^shadow)"
if [[ -z $SHADOWGROUPCHECK ]]
then
  sudo groupadd shadow
fi

sudo chgrp shadow /etc/shadow
sudo chmod g+r /etc/shadow

sudo usermod -a -G shadow $USERNAME

# Check if jupyteruser group exists already
JUPYTERUSERGROUPCHECK="$(sudo cat /etc/group | grep ^jupyteruser)"
if [[ -z $JUPYTERUSERGROUPCHECK ]]
then
  sudo groupadd jupyteruser
fi

echo "" | sudo tee -a /etc/sudoers >> $OUTPUT
echo "# the command the Hub can run on behalf of the above users without needing a password" | sudo tee -a /etc/sudoers >> $OUTPUT
echo "# the exact path may differ, depending on how sudospawner was installed" | sudo tee -a /etc/sudoers >> $OUTPUT
echo "Cmnd_Alias JUPYTER_CMD = /local/datacube/miniconda3/envs/cubeenv/bin/sudospawner" | sudo tee -a /etc/sudoers >> $OUTPUT
echo "" | sudo tee -a /etc/sudoers >> $OUTPUT
echo "# actually give the Hub user permission to run the above command on behalf" | sudo tee -a /etc/sudoers >> $OUTPUT
echo "# of the jupyteruser group without prompting for a password" | sudo tee -a /etc/sudoers >> $OUTPUT
echo "$USERNAME ALL=(%jupyteruser) NOPASSWD:JUPYTER_CMD" | sudo tee -a /etc/sudoers >> $OUTPUT

sudo mkdir /local/datacube/jupyterhub
sudo chown $USERNAME /local/datacube/jupyterhub

# Useless code, pending deletion
#cd /local/datacube/jupyterhub
#sudo -u rhea jupyterhub --JupyterHub.spawner_class=sudospawner.SudoSpawner

# Create a system service for JupyterHub
SERVICEFILE=/lib/systemd/system/jupyterhub.service
CHECKSERVICEFILE="$(ls /lib/systemd/system | grep jupyterhub)"
if [[ -z $CHECKSERVICEFILE ]]
then
  sudo touch $SERVICEFILE
  echo "[Unit]" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "Description=Jupyterhub" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "After=network-online.target" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "[Service]" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "User=$USERNAME" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "WorkingDirectory=/local/datacube/jupyterhub" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "ExecStartPre=/bin/bash -c 'PATH=/local/datacube/miniconda3/envs/cubeenv/bin:\$PATH && exec /bin/bash /local/datacube/miniconda3/envs/cubeenv/etc/conda/activate.d/gdal-activate.sh'" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "ExecStartPre=/bin/bash -c 'PATH=/local/datacube/miniconda3/envs/cubeenv/bin:\$PATH && exec /bin/bash /local/datacube/miniconda3/envs/cubeenv/etc/conda/activate.d/proj4-activate.sh'" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "ExecStart=/bin/bash -c 'PATH=/local/datacube/miniconda3/envs/cubeenv/bin:\$PATH exec /local/datacube/miniconda3/envs/cubeenv/bin/jupyterhub --JupyterHub.spawner_class=sudospawner.SudoSpawner'" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "KillSignal=SIGINT" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "[Install]" | sudo tee -a $SERVICEFILE >> $OUTPUT
  echo "WantedBy=multi-user.target" | sudo tee -a $SERVICEFILE >> $OUTPUT
else
  echo "File jupyterhub.service exists. Please overwrite this file manually"
fi

echo "You have successfully enabled user $USERNAME running JupyterHub."
echo "To start JupyterHub, use command: "
echo "  sudo systemctl start jupyterhub"
echo ""
echo "To add a jupyter notebook user, use command: "
echo "  adduser -G jupyteruser (newuser) -s /sbin/nologin"