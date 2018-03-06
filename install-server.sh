#!/bin/bash

#####################################################################
# COMMAND LINE INPUT
#####################################################################
DATABASE_NAME="fondefviz"
POSTGRES_USER="fondefvizuser"
POSTGRES_PASS="fondefvizpass"

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
PROJECT_NAME="fondefVizServer"
VIRTUAL_ENV_PATH="$PROJECT_DEST"/"$PROJECT_NAME"/myenv
PYTHON_EXECUTABLE="$VIRTUAL_ENV_PATH"/bin/python
SUBDOMAIN="fondefviz"

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
    apt-get --yes --force-yes install nodejs npm

    # install bower
    npm install -g bower
    # update bower to latest version
    npm i -g bower

    # install pip
    wget https://bootstrap.pypa.io/get-pip.py
    python get-pip.py
    pip install virtualenv
    rm get-pip.py
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

  cd "$INSTALLATION_PATH"

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
    python replace_config_psql.py "$PSQL_VERSION"
    service postgresql restart

    # create user and database
    POSTGRES_FINAL_FILE=postgresql_config.sql
    # copy the template
    cp template_postgresql_config.sql "$POSTGRES_FINAL_FILE"
    # change parameters
    sed -i -e 's/<DATABASE>/'"$DATABASE_NAME"'/g' "$POSTGRES_FINAL_FILE"
    sed -i -e 's/<USER>/'"$POSTGRES_USER"'/g' "$POSTGRES_FINAL_FILE"
    sed -i -e 's/<PASSWORD>/'"$POSTGRES_PASS"'/g' "$POSTGRES_FINAL_FILE"

    # postgres user has to be owner of the file and folder that contain the file
    CURRENT_OWNER=$(stat -c '%U' .)
    chown postgres "$POSTGRES_FINAL_FILE"
    chown postgres "$INSTALLATION_PATH"
    # create user and database
    sudo -u postgres psql -f "$POSTGRES_FINAL_FILE"
    rm "$POSTGRES_FINAL_FILE"
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

  # to Documents folder
  if cd $PROJECT_DEST; then
     pwd
  else
    sudo -u "$USER_NAME" mkdir -p "$PROJECT_DEST"
  fi

  # go to destination project path
  cd "$PROJECT_DEST"

  # clone project from git
  echo "Cloning project from gitHub..."
  sudo -u "$USER_NAME" git clone https://github.com/SmartcitySantiagoChile/fondefVizServer.git

  cd "$PROJECT_NAME"
  sudo -u "$USER_NAME" git submodule init
  sudo -u "$USER_NAME" git submodule update

  # configure wsgi
  cd "$INSTALLATION_PATH"
  python wsgi_config.py "$PROJECT_DEST" "$PROJECT_NAME"

  # configure subdomain
  DJANGO_SETTING_FILE="$PROJECT_DEST/$PROJECT_NAME/$PROJECT_NAME/settings.py"
  sed -i -e 's/JS_REVERSE_SCRIPT_PREFIX = ""/JS_REVERSE_SCRIPT_PREFIX = "/'"$SUBDOMAIN"'"/g' "$DJANGO_SETTING_FILE"

  # create secret_key.txt file
  SECRET_KEY_FILE="$PROJECT_DEST"/"$PROJECT_NAME"/"$PROJECT_NAME"/keys/secret_key.py
  sudo -u "$USER_NAME" touch $SECRET_KEY_FILE
  echo "SECRET_KEY=\"putYourSecretKeyHere\"" > "$SECRET_KEY_FILE"

  # create database file
  DJANGO_DATABASE_FILE="$PROJECT_DEST"/"$PROJECT_NAME"/"$PROJECT_NAME"/keys/database.py
  sudo -u "$USER_NAME" cp template_database_django_setup.py "$DJANGO_DATABASE_FILE"
  # change parameters
  sed -i -e 's/<DATABASE>/'"$DATABASE_NAME"'/g' "$DJANGO_DATABASE_FILE"
  sed -i -e 's/<USER>/'"$POSTGRES_USER"'/g' "$DJANGO_DATABASE_FILE"
  sed -i -e 's/<PASSWORD>/'"$POSTGRES_PASS"'/g' "$DJANGO_DATABASE_FILE"

  # create folder used by loggers if not exist
  LOG_DIR="$PROJECT_DEST"/"$PROJECT_NAME"/"$PROJECT_NAME"/logs
  sudo -u "$USER_NAME" mkdir -p "$LOG_DIR"
  sudo -u "$USER_NAME" touch "$LOG_DIR"/file.log
  chmod 777 "$LOG_DIR"/file.log
  sudo -u "$USER_NAME" touch "$LOG_DIR"/dbfile.log
  chmod 777 "$LOG_DIR"/dbfile.log

  # create virtualenv
  virtualenv "$VIRTUAL_ENV_PATH"

  PIP_EXECUTABLE="$VIRTUAL_ENV_PATH"/bin/pip
  COVERAGE_EXECUTABLE="$VIRTUAL_ENV_PATH"/bin/coverage
  # install all dependencies of python to the project
  cd "$PROJECT_DEST"/"$PROJECT_NAME"
  "$PIP_EXECUTABLE" install -r requirements.txt

  # initialize the database
  "$PYTHON_EXECUTABLE" manage.py migrate

  # add fixtures
  "$PYTHON_EXECUTABLE" manage.py loaddata datasource communes daytypes halfhours operators timeperiods

  # install js libraries
  sudo -u "$USER_NAME" bower install

  # collect static
  "$PYTHON_EXECUTABLE" manage.py collectstatic_js_reverse
  "$PYTHON_EXECUTABLE" manage.py collectstatic --clear --no-input

  #running test
  "$COVERAGE_EXECUTABLE" run --omit="rqworkers/dataUploader/*" --source='.' manage.py test
  "$COVERAGE_EXECUTABLE" report --omit="$PROJECT_NAME"/*,"$VIRTUAL_ENV_PATH"/* -m

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

  sudo python config_apache.py "$PROJECT_DEST" "$VIRTUAL_ENV_PATH" "$CONFIG_APACHE" "$PROJECT_NAME" "$SUBDOMAIN"
  sudo a2dissite 000-default.conf
  sudo a2ensite "$CONFIG_APACHE"
  sudo a2enmod headers 

  sudo service apache2 reload

  # change the MPM of apache.
  # MPM is the way apache handles the request
  # using processes, threads or a bit of both.

  # this is the default 
  # is though to work whith php
  # because php isn't thread safe.
  # django works better with
  # MPM worker, but set up
  # the number of precess and
  # threads with care.

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
  sudo python apache_setup.py 1 10 50 30 25 75

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
  sudo python rq_worker_config.py "$PROJECT_DEST/$PROJECT_NAME" "$PYTHON_EXECUTABLE"

  # Makes the service script executable
  cd "$PROJECT_DEST/$PROJECT_NAME/rqworkers"
  sudo chmod 775 djangoRqWorkers.sh

  # Enables and restarts the service
  sudo systemctl enable django-worker
  sudo systemctl daemon-reload
  sudo systemctl restart django-worker

  echo ----
  echo ----
  echo "Django-rq worker service configuration ready"
  echo ----
  echo ----


  echo "Ready, if everything went well you stop here."
  echo "Otherwise run in the project folder python manage.py runserver 0.0.0.0:8080 and try it,"
  echo "See what went wrong."
  echo "Also check if you can access to database, with "
  echo "$ psql ghostinspector --user=inspector (the password is inside the settings.py of the project)."
fi

cd "$INSTALLATION_PATH"
