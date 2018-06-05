#!/bin/bash

NOFIREWALLD=false
VERBOSE=false
OUTPUT="$HOME/dc_database_install.log"

for i in "$@"
do
case $i in
    -h|--help)
    echo "Usage: $0 [-h|--help] [-v|--verbose] [--no-firewalld]"
    echo "  -h|--help           display this help message"
    echo "  -v|--verbose        display all installation messages"
    echo "  --no-firewalld      do not configure firewalld"
    exit 0
    ;;
    -v|--verbose)
    VERBOSE=true
    OUTPUT="/dev/stdout"
    ;;
    --no-firewalld)
    NOFIREWALLD=true
    ;;
    *)
    echo unknown option $i
    ;;
esac
done

echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "@@      Welcome to Datacube      @@"
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"

echo "Database installation script has been deprecated"
echo "The file is pending deletion by next update."

exit 0

# Maintain sudo permission and ensure it will not timeout
# Revert the timeout settings at the end of the script
echo @ Requesting super user permission
sudo sed -i "s/Defaults    env_reset/Defaults    env_reset,timestamp_timeout=-1/g" /etc/sudoers
sudo echo

echo Updating local system...
sudo yum install -y deltarpm >> $OUTPUT
sudo yum update -y >> $OUTPUT

# Suppress directory permission denied messages
cd /

echo Installing PostgreSQL 9.6...
sudo yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm -y >> $OUTPUT
sudo yum install postgresql96 postgresql96-server postgresql96-devel postgresql96-contrib -y >> $OUTPUT
sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb >> $OUTPUT

# Modify the database allowed connection origins
echo "host    all             all             samenet                 md5" | sudo tee -a /var/lib/pgsql/9.6/data/pg_hba.conf >> $OUTPUT
sudo -u postgres sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/9.6/data/postgresql.conf

sudo systemctl enable postgresql-9.6 --quiet
sudo systemctl start postgresql-9.6

# Configure the postgres user password to complete the postgres setup
echo "======================= Please Read ========================="
echo " Please create a strong password for default postgres user"
echo " This will help secure the system. "
echo ""
echo " This will NOT be the password that you will need to "
echo " set up the server!"
echo "============================================================="
sudo -u postgres psql postgres -c "\password postgres"

# Create a User and Database
echo "Creating a new database user for datacube..."
    
while true
do
echo "Please enter the username for datacube"
echo -n "--> Enter new username: "
read USERNAME
if [[ $USERNAME != "" ]]
then
    break
fi
echo "Cannot accept empty username!"
done

sudo -u postgres createuser --superuser $USERNAME
sudo -u postgres psql -c "\password $USERNAME"
sudo -u postgres psql -c "create database datacube owner $USERNAME;" >> $OUTPUT

if [[ $NOFIREWALLD = false ]]
then
    echo "Setting up firewall..."
    sudo firewall-cmd --zone=public --add-port=5432/tcp --permanent >> $OUTPUT
    sudo firewall-cmd --reload >> $OUTPUT
fi

# Revert sudo timeout settings
sudo sed -i "s/Defaults    env_reset,timestamp_timeout=-1/Defaults    env_reset/g" /etc/sudoers

echo
echo "Database for Datacube has been installed! You can now proceed and install Datacube."
echo "You will need database server IP address, username and password."
if [[ $VERBOSE = false ]]
then
    echo "Log file of this installation has been saved to $OUTPUT."
fi
