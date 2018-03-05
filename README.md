# install-elastic
These are scripts to install, configure and run Elasticsearch and Cerebro 0.7.2 (github.com/lmenezes/cerebro) on Ubuntu 16.04.3 LTS as services. The scripts allow these applications to automatically run on bootup.

To run them, execute:<br>
```
$ chmod +x *.sh
$ ./requirements.sh
$ ./install-elastic.sh
$ ./install-cerebro.sh
$ ./install-redis.sh
$ ./install-server.sh
```
The scripts asks for IP and port. Additionally the Elasticsearch script will ask for the (absolute) data path and amount of RAM to use.

# install elasticsearch

Execute ´./install-elastic.sh´. This script installs version 6.0 of elasticsearch, additionally

The scripts asks for IP, port and the (absolute) data path and amount of RAM to use.

# install cerebro

Execute ´./install-cerebro.sh´. This script installs version 6.0 of elasticsearch, additionally

The scripts asks for IP and port.

# install redis

Execute ´./install-redis.sh´

# install server

The base behavior of the script creates a user with name **server** and the project will be located in path ´/home/server´

This script has 5 steps:

    1. Step 1: install dependencies
    2. Step 2: postgres configuration: create database user and database
    3. Step 3: project configuration: download server project from github and create python virtual env to run it in isolated mode
    4. Step 4: apache configuration: install and set apache to link server project to url base /
    4. Step 5: django rq worker: workers of python rq that execute async tasks to upload files or create download files

It is highly recommended to read the script before running it and ALSO EXECUTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on install-server.sh to select which steps you want to run. The recommended way is to deactivate all steps and run them separately.

# First Access

At the first time there is not users in the system so you can not access to web site, to fix this problem you need to execute the next command
´´´
# activate virtual environment
source myenv/bin/activate
# create super user
python manage.py createsuperuser
´´´
With this new user you can create others through django admin web page (´<ip>/admin´)
