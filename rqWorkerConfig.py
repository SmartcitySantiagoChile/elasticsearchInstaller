import sys
import os


def getWorkerService(server_folder):
    return '''[Unit]
Description= Django-rq worker service
RequiresMountsFor= ''' + server_folder + '''
PartOf= apache2.service
After= apache2.service
[Service]
ExecStart= ''' + server_folder + '''/rqworkers/djangoRqWorkers.sh
Restart= on-failure
KillMode= process
[Install]
WantedBy= apache2.service
WantedBy= multi-user.target'''


def getWorkerScript(server_folder):
    return '''#!/bin/bash
########################################################
# CREATE RQ WORKERS BASED ON CONFIG FILE
########################################################
# On termination kill all workers, then reset trap
trap 'kill -TERM $(jobs -p); trap - INT;' TERM
# Read config file and start workers
while IFS='|' read -r -a line || [[ -n "$line" ]]; do
  for (( i=0; i<"${line[0]}"; i++ )) do
    /usr/bin/python2.7 ''' + server_folder + '''/manage.py \
    rqworker ${line[1]} --worker-class "rqworkers.${line[2]}" &
    done
done < ''' + server_folder + '''/rqworkers/worker_config.txt
# First wait keeps the process running, waiting the workers to end
wait
# Second wait keeps the process running while the workers end gracefully
wait'''


if len(sys.argv) < 2:
    pass
else:
    # Create service and script files
    service_str = getWorkerService(sys.argv[1])
    script_str = getWorkerScript(sys.argv[1])

    # Necessary paths
    systemd_path = '/etc/systemd/system/django-worker.service'
    script_path = sys.argv[1] + '/rqworkers/djangoRqWorkers.sh'
    config_path = sys.argv[1] + '/rqworkers/worker_config.txt'

    # Write the service file to the correct path
    with open(systemd_path, 'w+') as service_file:
        service_file.write(service_str)

    # Write the script file to the correct path
    with open(script_path, 'w+') as script_file:
        script_file.write(script_str)

    # Write a dummy config if there's no configuration
    if not os.path.exists(config_path):
        with open(config_path, 'w+') as config_file:
            config_file.write('0|queue1 queue2|path.to.worker.class')
