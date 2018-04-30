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

#
# Fresh CentOS 7 VM - GUI_Server+development
#
sudo yum update -y
sudo reboot

# Python-3.6.4 from source
# - requires zlib-devel
# - requires openssl-devel
sudo pip3 install --upgrade pip
sudo pip3 install pycosat
sudo pip3 install pyyaml
sudo pip3 install requests
cd
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
sh Miniconda3-latest-Linux-x86_64.sh		# interactive install
conda update conda
conda config --add channels conda-forge
#
# To activate this environment, use:
# > source activate cubeenv
#
# To deactivate an active environment, use:
# > source deactivate
#
conda create --name cubeenv python=3.6 datacube # requires confirmation
conda install jupyter matplotlib scipy

sudo yum install postgresql10 postgresql10-server postgresql10-devel postgresql10-contrib
# /var/lib/pgsql/10/data/pg_hba.conf - TODO: script this
#
# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     peer
host    replication     all             127.0.0.1/32            ident
host    replication     all             ::1/128                 ident

#
sudo /usr/pgsql-10/bin/postgresql-10-setup initdb
sudo systemctl enable postgresql-10
sudo systemctl start postgresql-10

yum install pgadmin4-v2 -y

# ~/.datacube.conf
[datacube]
db_database: datacube

# A blank host will use a local socket. Specify a hostname (such as localhost) to use TCP.
db_hostname: localhost

# Credentials are optional: you might have other Postgres authentication configured.
# The default username otherwise is the current user id.
db_username: datacube
db_password: ********

source activate cubeenv
