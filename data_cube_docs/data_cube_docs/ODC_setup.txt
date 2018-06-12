# ODC Requirements:
#	- Python 3.5+ (3.6 recommended)
#	- GDAL
#	- PostgreSQL database
#
# Miniconda Requirements:
#	- Python 2.7, 3.4, 3.5 or 3.6.
#	- pycosat
#	- PyYaml
#	- Requests
# VM requirements
# - 8GB+ RAM
# - 50GB local storage
#
# Fresh CentOS 7 VM - GUI_Server+development
#
sudo yum update -y
sudo reboot

# Add IUS (Inline With Upstream)  3rd party repository for Python 3.6
# -------------------------------------------------------
sudo yum install https://centos7.iuscommunity.org/ius-release.rpm -y
sudo yum install python36u -y
sudo yum install python36u-pip -y
sudo yum install python36u-devel -y

# Install extra packages if using minimal installation of CentOS
sudo yum install gcc bzip2 -y

# - requires zlib-devel
# - requires openssl-devel
# Install Python packages using pip
# Because of $PATH interactions with sudo, may need to navigate to directory in which pip3 lives to execute the pip3 commands
# \usr\local\bin, run as ./pip3 
# -------------------------------------------------------
sudo pip3.6 install pycosat pyyaml requests

# Conda used for package, dependency and environment management for any language, cross-platform
# -------------------------------------------------------
curl -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
sh Miniconda3-latest-Linux-x86_64.sh		# interactive install
source ~/.bashrc
conda update conda
conda config --add channels conda-forge
conda create --name cubeenv python=3.6 datacube # requires confirmation

#
# To activate the conda environment, use:
# conda activate cubeenv
# To deactivate an active environment, use:
# conda deactivate
#

# *** This is optional and only really needed for a dev environment ***
# Matplotlib provides both a very quick way to visualize data from Python
# Scipi is a Python-based ecosystem of open-source software for mathematics, science, and engineering
# Jupyter Notebook is an open-source web application that allows you to create and share documents
# that contain live code, equations, visualizations and narrative text
# -------------------------------------------------------
conda install jupyter matplotlib scipy

# Install PostgreSQL 9.6
#--------------------------------------------------------
sudo yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm
sudo yum install postgresql96 postgresql96-server postgresql96-devel postgresql96-contrib
sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb

# EDIT BEGIN : 
# /var/lib/pgsql/9.6/data/pg_hba.conf - TODO: script this
#
# TYPE  DATABASE        USER            ADDRESS                 METHOD
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
# Allow replication connections from localhost, by a user with the replication privilege.
#local   replication     all                                     peer
#host    replication     all             127.0.0.1/32            ident
#host    replication     all             ::1/128                 ident
# EDIT END 

sudo systemctl enable postgresql-9.6
sudo systemctl start postgresql-9.6

# Configure the postgres user password to complete the postgres setup
#--------------------------------------------------------
# Open interactive shell as the "root" user postgres
# the only user who can connect to a fresh install is the postgres user
sudo -u postgres psql postgres
\password postgres

# Will prompt for password
# Type Control+D or \q to exit the posgreSQL prompt.

# Create a User
#--------------------------------------------------------
# Create a superuser database account (which is in this case also a database superuser) with the same name as your login name and then create a password for the user:
sudo -u postgres createuser --superuser <username>
sudo -u postgres psql
postgres=# \password <username>

#Create Database
#--------------------------------------------------------
#if authenticated & using interactive shell:
create database datacube owner <username> ;

#or specify connection details manually if not authenticated:
createdb -h <hostname> -U <username> datacube

#install pgadmin for db stuff, this can be done anytime, not required at this point. 
#yum install pgadmin4-v2 -y

#Create Configuration File
#--------------------------------------------------------
#Datacube looks for a configuration file in ~/.datacube.conf or in the location specified by the DATACUBE_CONFIG_PATH environment variable.
# The configuration file is like a "connection string" for the database
#EDIT BEGIN : 
# ~/.datacube.conf

[datacube]
db_database: datacube
# A blank host will use a local socket. Specify a hostname (such as localhost) to use TCP.
db_hostname: localhost

# Credentials are optional: you might have other Postgres authentication configured.
# The default username otherwise is the current user id.
db_username: <username>
db_password: <password>

# EDIT END 

# Enter the conda environment, will need this environment for subsequent tasks
source activate cubeenv
# initialize the datacube schema, do this ONLY ONCE!
datacube -v system init


# get git & ODC code
sudo yum install git
git clone https://github.com/opendatacube/datacube-core
cd datacube-core
git checkout develop


# Run jupyter notebook server, will launch a browser window. This step is for fun, and to make sure jupyter is ago!
# This needs to be run in the conda environment
jupyter-notebook
# A directory of the notebook is displayed in the browser, open examples -> notebooks and find the 
