#!/bin/bash

#####################################################################
# COMMAND LINE INPUT
#####################################################################
if [ -z "$1" ]; then
    echo "No se especifico la ip del servidor"
    exit 
fi

IP_SERVER=$1
DATABASE_NAME=${2:="fondefviz"}

#####################################################################
# CONFIGURATION
#####################################################################

install_packages=true
postgresql_configuration=false
project_configuration=false
apache_configuration=false
django_worker_config=false

USER_NAME="server"
PROJECT_DEST=/home/"$USER_NAME"


INSTALLATION_PATH=$(pwd)

#####################################################################
# USER CONFIGURATION
#####################################################################

# stores the current path
if id "$USER_NAME" >/dev/null 2>&1; then
    echo "User $USER_NAME already exists.. skipping"
else
    echo "User $USER_NAME does not exists.. CREATING!"
    adduser $USER_NAME
fi


#####################################################################
# REQUIREMENTS
#####################################################################

if $install_packages; then
    # Install all necesary things
    # use eog to view image through ssh by enabling the -X flag
    # Ejample: ssh -X .....
    # then run eog <image>
    # and wait 
    apt-get update 
    apt-get upgrade

    apt-get --yes --force-yes install build-essential apache2 git python-setuptools libapache2-mod-wsgi python-dev libpq-dev postgresql postgresql-contrib 
    
    # easy_install is a python module bundled with setuptools that lets you automatically download, build, install, and manage Python packages.
    easy_install pip
fi


#####################################################################
# POSTGRESQL
#####################################################################
if $postgresql_configuration; then
  echo ----
  echo ----
  echo "Postgresql"
  echo ----
  echo ----

  CREATE_DATABASE=true
  DATABASE_EXISTS=$(sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -w "$DATABASE_NAME")
  if [ "$DATABASE_EXISTS" ]; then
      echo ""
      echo "The database $DATABASE_NAME already exists."
      read -p "Do you want to remove it and create it again? [Y/n]: " -n 1 -r
      echo # (optional) move to a new line
      CREATE_DATABASE=false
      if [[ $REPLY =~ ^[Yy]$ ]]
      then
        echo "Removing database $DATABASE_NAME..."
        sudo -u postgres psql -c "DROP DATABASE $DATABASE_NAME;"
        CREATE_DATABASE=true
      fi
  fi

  if "$CREATE_DATABASE" ; then
    # get the version of psql
    PSQL_VERSION=$(psql -V | egrep -o '[0-9]{1,}\.[0-9]{1,}')
    # change config of psql
    cd "$INSTALLATION_PATH"
    python replace_config_psql.py "$PSQL_VERSION"
    service postgresql restart

    # postgres user has to be owner of the file and folder that contain the file
    CURRENT_OWNER=$(stat -c '%U' .)
    chown postgres "$INSTALLATION_PATH"/postgresql_config.sql
    chown postgres "$INSTALLATION_PATH"
    # create user and database
    sudo -u postgres psql -f "$INSTALLATION_PATH"/postgresql_config.sql
    chown "${CURRENT_OWNER}" "$INSTALLATION_PATH"/postgresql_config.sql
    chown "${CURRENT_OWNER}" "$INSTALLATION_PATH"

  fi

  echo ----
  echo ----
  echo "Postgresql ready"
  echo ----
  echo ----
fi


#####################################################################
# CLONE SETUP DJANGO APP
#####################################################################
if $project_configuration; then
  echo ----
  echo ----
  echo "Project configuration"
  echo ----
  echo ----

  echo ""
  echo --
  echo "Server directory: "
  echo --
  echo ""

  # to Documents folder
  if cd $PROJECT_DEST; then
     pwd
  else
    mkdir -p $PROJECT_DEST
  fi

  # go to project destination path
  cd $PROJECT_DEST

  # clone project from git
  echo ""
  echo ----
  echo "Clone project from gitHub"
  echo ----
  echo ""
  git clone https://github.com/SmartcitySantiagoChile/fondefVizServer.git
  PROJECT_NAME="fondefVizServer"
  cd "$PROJECT_NAME"
  git submodule init
  git submodule update
  cd ..

  # configure wsgi
  cd "$INSTALLATION_PATH"
  python wsgi_config.py "$PROJECT_DEST"

  # create secret_key.txt file
  SECRET_KEY_FILE=$PROJECT_DEST/"$PROJECT_NAME"/"$PROJECT_NAME"/keys/secret_key.txt
  touch $SECRET_KEY_FILE
  echo "putYourSecretKeyHere" > "$SECRET_KEY_FILE"

  # create folder used by loggers if not exist
  LOG_DIR="$PROJECT_DEST"/"$PROJECT_NAME"/"$PROJECT_NAME"/logs
  mkdir -p "$LOG_DIR"
  touch $LOG_DIR/file.log
  chmod 777 "$LOG_DIR"/file.log
  touch $LOG_DIR/dbfile.log
  chmod 777 "$LOG_DIR"/dbfile.log

  # install all dependencies of python to the project
  cd "$PROJECT_DEST"/"$PROJECT_NAME"
  pip install -r requirements.txt

  # initialize the database
  python manage.py makemigrations
  python manage.py migrate
  
  # add fixtures
  python manage.py loaddata datasource communes daytypes halfhours operators timeperiods

  #running test
  coverage run --source='.' manage.py test
  coverage report --omit="$PROJECT_NAME"/* -m

  echo ----
  echo ----
  echo "Project configuration ready"
  echo ----
  echo ----
fi


#####################################################################
# APACHE CONFIGURATION
#####################################################################
if $apache_configuration; then
  echo ----
  echo ----
  echo "Apache configuration"
  echo ----
  echo ----
  # configure apache 2.4

  cd "$INSTALLATION_PATH"
  CONFIG_APACHE="fondefviz_server.conf"

  sudo python config_apache.py "$PROJECT_DEST" "$IP_SERVER" "$CONFIG_APACHE"
  sudo a2dissite 000-default.conf
  sudo a2ensite "$CONFIG_APACHE"
  # ssl configuration
  sudo cp ssl.conf /etc/apache2/mods-available
  sudo a2enmod ssl
  sudo a2enmod headers 

  sudo service apache2 reload

  # change the MPM of apache.
  # MPM is the way apache handles the request
  # using proceses, threads or a bit of both.

  # this is the default 
  # is though to work whith php
  # becuase php isn't thread safe.
  # django works better whith
  # MPM worker, but set up
  # the number of precess and
  # threads whith care.

  sudo a2dismod mpm_event 
  sudo a2enmod mpm_worker 

  # configuration for the worker
  # mpm.
  # apacheSetup arg1 arg2 arg3 ... arg7
  # arg1 StartServers: initial number of server processes to start
  # arg2 MinSpareThreads: minimum number of 
  #      worker threads which are kept spare
  # arg3 MaxSpareThreads: maximum number of
  #      worker threads which are kept spare
  # arg4 ThreadLimit: ThreadsPerChild can be 
  #      changed to this maximum value during a
  #      graceful restart. ThreadLimit can only 
  #      be changed by stopping and starting Apache.
  # arg5 ThreadsPerChild: constant number of worker 
  #      threads in each server process
  # arg6 MaxRequestWorkers: maximum number of threads
  # arg7 MaxConnectionsPerChild: maximum number of 
  #      requests a server process serves
  cd "$INSTALLATION_PATH"
  sudo python apacheSetup.py 1 10 50 30 25 75

  sudo service apache2 restart

  # this lets apache add new things to the media folder
  # to store the pictures of the free report
  sudo adduser www-data "$USER_NAME"

  echo ----
  echo ----
  echo "Apache configuration ready"
  echo ----
  echo ----
fi


#####################################################################
# DJANGO-RQ WORKER SERVICE CONFIGURATION
#####################################################################
if $django_worker_config; then
  echo ----
  echo ----
  echo "Django-rq worker service configuration"
  echo ----
  echo ----

  cd "$INSTALLATION_PATH"

  # Creates the service unit file and the service script
  sudo python rqWorkerConfig.py "$PROJECT_DEST/server"

  # Makes the service script executable
  cd "$PROJECT_DEST/server/rqworkers"
  sudo chmod 775 djangoRqWorkers.sh
  cd "$INSTALLATION_PATH"

  # Enables and restarts the service
  sudo systemctl enable django-worker
  sudo systemctl daemon-reload
  sudo systemctl restart django-worker

  echo ----
  echo ----
  echo "Django-rq worker service configuration ready"
  echo ----
  echo ----

fi

cd "$INSTALLATION_PATH"

echo "Ready, if everything went well you stop here."
echo "Otherwise run in the project folder python manage.py runserver 0.0.0.0:8080 and try it,"
echo "See what went wrong."
echo "Also check if you can acces the database, with "
echo "$ psql ghostinspector --user=inspector (the password is inside the settings.py of the project)."
