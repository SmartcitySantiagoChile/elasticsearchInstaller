#!/bin/bash

# Download and install Elasticsearch
# Check http://www.elasticsearch.org/download/ for latest version and replace wget link
# Only download the file if it doesn't already exist
if [ ! -f elasticsearch-6.2.3.deb ]; then
    wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-6.2.3.deb
fi
# Install deb
sudo dpkg -i elasticsearch-6.2.3.deb

# Set JAVA_HOME (in case it is not automatically set)
export JAVA_HOME=/usr/lib/jvm/java-8-oracle

# Enable on bootup
sudo systemctl enable elasticsearch.service

# Ask user for path to store data
_repeatPath="Y"
while [ $_repeatPath = "Y" ]
do
	echo -n "Enter path to data directory (leave blank for default: /var/lib/elasticsearch): "
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

# Start ElasticSearch 
sudo /etc/init.d/elasticsearch start
sleep 10
echo Please wait...
sleep 20 #Elasticsearch takes between 25-30 seconds to start

# Check if Elasticsearch service is running
curl http://$IP:$PORT

# The output should be something like this:
#{
#  "name" : "kxIjFbl",
#  "cluster_name" : "elasticsearch",
#  "cluster_uuid" : "zoEkL7aBSZC9t8H0V4LLOg",
#  "version" : {
#    "number" : "6.2.3",
#    "build_hash" : "8f0685b",
#    "build_date" : "2017-11-10T18:41:22.859Z",
#    "build_snapshot" : false,
#    "lucene_version" : "7.0.1",
#    "minimum_wire_compatibility_version" : "5.6.0",
#    "minimum_index_compatibility_version" : "5.0.0"
#  },
#  "tagline" : "You Know, for Search"
#}

echo "Done. Elasticsearch is now running on http://"$IP":"$PORT"."
