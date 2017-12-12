#!/bin/bash

# Install requirements
./requirements

## Download and install Elasticsearch
## Check http://www.elasticsearch.org/download/ for latest version of Elasticsearch and replace wget link
# Only download the file if it does not already exist
if [ ! -f elasticsearch-6.0.0.deb ]; then
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.0.0.deb
fi
# Install deb
sudo dpkg -i elasticsearch-6.0.0.deb

# Enable Elastic to start on bootup
sudo update-rc.d elasticsearch defaults 95 10

# Set JAVA_HOME (in case it is not automatically set)
export JAVA_HOME=/usr/lib/jvm/java-8-oracle

# Ask user for path to store data
_repeatPath="Y"
while [ $_repeatPath = "Y" ]
do
	echo -n "Enter path to data directory, separate multiple locations by comma (leave blank for default): "
read DPATH
# If empty, then set the default path
if [ -z "$DPATH" ]; then
    sudo sed -i 's|^path.data: .*$|path.data: /var/lib/elasticsearch|' /etc/elasticsearch/elasticsearch.yml
    echo "Set to the default path"
    _repeatPath="N"
# Else, check if the path exists; if it doesn't ask again
elif [ ! -e "$DPATH" ]; then
    echo "Invalid path"
else
    # Give permissions to elasticsearch (this is the default user running the application)
    setfacl -m u:elasticsearch:rwx $DPATH
    # Replace the old path with the given one
    sudo sed -i 's|^path.data: .*$|path.data: '"$DPATH"'|' /etc/elasticsearch/elasticsearch.yml 
    _repeatPath="N"
fi
done

# Ask user to set IP
_repeatIP="Y"
while [ $_repeatIP = "Y" ]
do
	echo -n "Enter IP address: "
read IP
# If empty
if [ -z "$IP" ]; then
    : # Do nothing
else
    # Replace IP
    sudo sed -i 's|^[#]*network.host: .*$|network.host: '"$IP"'|' /etc/elasticsearch/elasticsearch.yml
    _repeatIP="N"
fi
done

# Ask user to set port
_repeatPort="Y"
while [ $_repeatPort = "Y" ]
do
	echo -n "Enter port number: "
read PORT
# If empty
if [ -z "$PORT" ]; then
    : # Do nothing
else
    # Replace port
    sudo sed -i 's|^[#]*http.port: .*$|http.port: '"$PORT"'|' /etc/elasticsearch/elasticsearch.yml 
    _repeatPort="N"
fi
done

# Ask user to set amount of RAM
echo "RAM setting. Do not set more than 50% of available RAM. Do not exceed 32 GB. Less than 8 GB tends to be counterproductive."
echo -n "Enter RAM amount in GB: "
read RAM
sudo sed -i 's|^-Xms.*$|-Xms'"$RAM"'g|' /etc/elasticsearch/jvm.options
sudo sed -i 's|^-Xmx.*$|-Xms'"$RAM"'g|' /etc/elasticsearch/jvm.options

# Start Elasticsearch
sudo /etc/init.d/elasticsearch start

# Check if elasticsearch service is running
curl http://$IP:$PORT

# Should return something like this:
# {
#  "status" : 200,
#  "name" : "Storm",
#  "version" : {
#    "number" : "1.3.1",
#    "build_hash" : "2de6dc5268c32fb49b205233c138d93aaf772015",
#    "build_timestamp" : "2014-07-28T14:45:15Z",
#    "build_snapshot" : false,
#    "lucene_version" : "4.9"
#  },
#  "tagline" : "You Know, for Search"
#}

sleep 3

# Download, install and run cerebro
if [ ! -f cerebro-0.7.2.tgz ]; then
wget https://github.com/lmenezes/cerebro/releases/download/v0.7.2/cerebro-0.7.2.tgz
fi

# Unpack cerebro
tar -zvxf cerebro-0.7.2.tgz
cd cerebro-0.7.2/

# Ask for cerebro port
echo -n "Define cerebro port: "
read CPORT
bin/cerebro -Dhttp.port=$CPORT -Dhttp.address=$IP
