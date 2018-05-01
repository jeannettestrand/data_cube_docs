#Create your base directory structure to hold all of the relevant codebases: We create everything in a directory 'Datacube' in the local user's directory.

mkdir ~/Datacube

# We also create a base directory structure for raw data and the ingested data in the root directory '/datacube/*'
sudo mkdir -p /datacube/{original_data,ingested_data}
sudo chmod -R 777 /datacube/

#Create a virtual environment named 'datacube_env' in the ~/Datacube director 
sudo pip3 install virtualenv
virtualenv ~/Datacube/datacube_env


# When installing Python packages, you'll need to have the virtual environment activated. This can be done with:
source ~/Datacube/datacube_env/bin/activate
#check the python version with:
python -V
#ensure that the output is 'Python 3.5.x'

# To exit the virtual environment, simply enter:
deactivate


# Checking Out Code-----------------------------------
# Ensure Git is installed
sudo apt-get install git

cd ~/Datacube
git clone https://github.com/ceos-seo/agdc-v2.git -b master
git clone https://github.com/ceos-seo/data_cube_ui.git -b master
git clone https://github.com/ceos-seo/data_cube_notebooks.git -b master
cd ~/Datacube/data_cube_ui
git submodule init && git submodule update
cd ~/Datacube/data_cube_notebooks
git submodule init && git submodule update

# Installation Process
# A few system level dependencies must be satisfied before the agdc-v2/datacube-core codebase can be installed.

sudo apt-get install -y postgresql-9.5 postgresql-client-9.5 postgresql-contrib-9.5
sudo apt-get install -y libhdf5-serial-dev libnetcdf-dev
sudo apt-get install -y libgdal1-dev
sudo apt-get install -y hdf5-tools netcdf-bin gdal-bin

# A few system level packages that are 'nice to have' or helpful if you are a new user/using Ubuntu desktop rather than server.

sudo apt-get install -y postgresql-doc-9.5 libhdf5-doc netcdf-doc libgdal-doc pgadmin3 tmux

# Now that all of the system level dependencies have been satisfied, there are some Python packages that must be installed before running the setup script. Ensure that you have your virtual environment activated and ready for use - You should see (datacube_env) on your terminal window.

pip install numpy
pip install --global-option=build_ext --global-option="-I/usr/include/gdal" gdal==1.11.2
pip install shapely
pip install scipy
pip install cloudpickle
pip install Cython
pip install netcdf4

# Please note that the installed gdal version should be as close to your system gdal version as possible, printed with:

gdalinfo --version
pip install gdal==99999999999

#Now that all requirements have been satisfied, run the setup.py script in the agdc-v2 directory:

# It has come to our attention that the setup.py script fails the first time it is run due to some NetCDF/Cython issues. Run the script a second time to install if this occurs.

cd ~/Datacube/agdc-v2
python setup.py develop

# This should produce a considerable amount of console output, but will ultimately end with a line resembling:
# Finished processing dependencies for datacube==1.1.15+367.g93ac52e


# System Configuration--------------------------------
# PostgreSQL Configuration--------------------------------
#Open  /etc/postgresql/9.5/main/postgresql.conf file as a super user
# ensure that the line starting with 'timezone' looks like
timezone = 'UTC'


#The following will ensure that you are able to authenticate via password when connecting to the database from the local system.
# open the /etc/postgresql/9.5/main/pg_hba.conf file
#change this:
# "local" is for Unix domain socket connections only
# local   all             all                                     peer

#to this:
# "local" is for Unix domain socket connections only
local   all             all                                     md5

sudo service postgresql restart
