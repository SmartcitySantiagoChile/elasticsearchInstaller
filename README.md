# install-elastic
These are scripts to install, configure and run Elasticsearch and Cerebro 0.7.2 (github.com/lmenezes/cerebro) on Ubuntu 16.04.3 LTS as services. The scripts allow these applications to automatically run on bootup.

To run them, execute:<br>
```
$ chmod +x *.sh
$ ./requirements.sh
$ ./install-elastic.sh
$ ./install-cerebro.sh
$ ./install-redis.sh
```
The scripts asks for IP and port. Additionally the Elasticsearch script will ask for the (absolute) data path and amount of RAM to use.
