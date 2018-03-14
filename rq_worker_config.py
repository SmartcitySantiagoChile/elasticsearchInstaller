# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import sys
import os


def get_worker_service(server_folder):
    return '''[Unit]
Description= Django-rq worker service
RequiresMountsFor= {0}
PartOf= apache2.service
After= apache2.service
[Service]
ExecStart= {0}/rqworkers/djangoRqWorkers.sh
Restart= on-failure
KillMode= process
[Install]
WantedBy= apache2.service
WantedBy= multi-user.target'''.format(server_folder)


def get_worker_script(server_folder, python_executable):
    return '''#!/bin/bash
########################################################
# CREATE RQ WORKERS BASED ON CONFIG FILE
########################################################
# On termination kill all workers, then reset trap
trap 'kill -TERM $(jobs -p); trap - INT;' TERM
# Read config file and start workers
while IFS='|' read -r -a line || [[ -n "$line" ]]; do
  for (( i=0; i<"${{line[0]}}"; i++ )) do
    {1} {0}/manage.py \
    rqworker ${{line[1]}} --worker-class "rqworkers.${{line[2]}}" &
    done
done < {0}/rqworkers/worker_config.txt
# First wait keeps the process running, waiting the workers to end
wait
# Second wait keeps the process running while the workers end gracefully
wait'''.format(server_folder, python_executable)


def main():
    if len(sys.argv) < 2:
        pass
    else:
        project_path = sys.argv[1]
        python_executable = sys.argv[2]
        # Create service and script files
        service_str = get_worker_service(project_path)
        script_str = get_worker_script(project_path, python_executable)

        # Necessary paths
        systemd_path = '/etc/systemd/system/django-worker.service'
        script_path = '{0}/rqworkers/djangoRqWorkers.sh'.format(project_path)
        config_path = '{0}/rqworkers/worker_config.txt'.format(project_path)

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


if __name__ == '__main__':
    main()
