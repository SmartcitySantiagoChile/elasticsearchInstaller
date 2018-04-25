# README
These are scripts to install, configure and run Elasticsearch, Cerebro 0.7.2 (github.com/lmenezes/cerebro) and redis on Ubuntu 16.04.3 LTS as services. The scripts allow these applications to automatically run on bootup.

Additionally we include installation script for visualization project

To run them, execute:<br>
```
$ chmod +x *.sh
$ ./requirements.sh
$ ./install-elastic.sh
$ ./install-cerebro.sh
$ ./install-redis.sh
$ ./install-server.sh
```

# install elasticsearch

Execute `./install-elastic.sh`. This script installs version 6.0 of elasticsearch, additionally

The scripts asks for IP, port and the (absolute) data path and amount of RAM to use.

# install cerebro

Execute `./install-cerebro.sh`. This script installs version 6.0 of elasticsearch, additionally

The scripts asks for IP and port.

# install redis

Execute `./install-redis.sh`

# install server

The base behavior of the script creates a user with name **server** and the project will be located in path `/home/server`

Before to run the script you have to define next variables inside ```install-server.sh``` file:

```
# Database connection params
DATABASE_NAME=""
POSTGRES_USER=""
POSTGRES_PASS=""
# If you want to put the project in www.host.cl/project, you have to define this variable to "project", if the project is hosted in root domaint it has to be empty string
SUBDOMAIN=""
# django secret key 
SECRET_KEY="SD3454562A234F234REF4R43G#$534234G%&#"

# elasticsearch connection params
ES_HOST="127.0.0.1"
ES_PORT="9200"

# redis connection params
REDIS_HOST="127.0.0.1"
REDIS_PORT="6379"

# A list of strings representing the host/domain names that this Django site can serve
ALLOWED_HOSTS='www.fondef.cl,123.123.13.123'

# configuration to send email when user ask for data and this data is 
EMAIL_HOST=""
EMAIL_PORT=""
EMAIL_USE_TLS=""
EMAIL_HOST_USER=""
EMAIL_HOST_PASSWORD=""
SERVER_EMAIL=""

# absolute path where system will put zip files to be downloaded by users
DOWNLOAD_PATH=""
```

This script has 5 steps:

1. Step 1: install dependencies
2. Step 2: postgres configuration: create database user and database
3. Step 3: project configuration: download server project from github and create python virtual env to run it in isolated mode
4. Step 4: apache configuration: install and set apache to link server project to url base /
5. Step 5: django rq worker: workers of python rq that execute async tasks to upload files or create download files

It is highly recommended to read the script before running it and ALSO EXECUTE IT BY ONE PIECE AT A TIME!. Modify the configuration section on install-server.sh to select which steps you want to run. The recommended way is to deactivate all steps and run them separately.

# First Access

At the first time there is not users in the system so you can not access to web site, to fix this problem you need to execute the next command
```
# activate virtual environment
source myenv/bin/activate
# create super user
python manage.py createsuperuser
```
With this new user you can create others through django admin web page (`<ip>/admin`)
