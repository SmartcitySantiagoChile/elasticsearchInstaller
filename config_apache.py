# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import sys


def get_config_http_file(project_path, project_name, virtualenv_path):
    return '''<VirtualHost *:80>
        # The ServerName directive sets the request scheme, hostname and port that
        # the server uses to identify itself. This is used when creating
        # redirection URLs. In the context of virtual hosts, the ServerName
        # specifies what hostname must appear in the request's Host: header to
        # match this virtual host. For the default virtual host (this file) this
        # value is not decisive as it is used as a last resort host regardless.
        # However, you must set it for any further virtual host explicitly.
        #ServerName www.example.com
        #ServerAdmin webmaster@localhost
        #DocumentRoot /var/www/html
        Alias /static {0}/{1}/static
        <Directory {0}/{1}/static>
                Require all granted
        </Directory>
        <Directory {0}/{1}/{1}>
                <Files wsgi.py>
                      Require all granted
                </Files>
        </Directory>
        LoadModule wsgi_module /usr/lib/apache2/modules/mod_wsgi.so
        WSGIDaemonProcess {1} python-path={0}/{1} python-home={2}
        WSGIProcessGroup {1}
        WSGIScriptAlias / {0}/{1}/{1}/wsgi.py
        # Available loglevels: trace8, ..., trace1, debug, info, notice, warn,
        # error, crit, alert, emerg.
        # It is also possible to configure the loglevel for particular
        # modules, e.g.
        #LogLevel info ssl:warn
        ErrorLog ${{APACHE_LOG_DIR}}/error.log
        CustomLog ${{APACHE_LOG_DIR}}/access.log combined
        # For most configuration files from conf-available/, which are
        # enabled or disabled at a global level, it is possible to
        # include a line for only one particular virtual host. For example the
        # following line enables the CGI configuration for this host only
        # after it has been globally disabled with "a2disconf".
        #Include conf-available/serve-cgi-bin.conf
    </VirtualHost>'''.format(project_path, project_name, virtualenv_path)


def main():
    if len(sys.argv) < 4:
        pass
    else:
        path_to_project = sys.argv[1]
        virtual_env_path = sys.argv[2]
        apache_config_file_name = sys.argv[3]
        project_name = sys.argv[4]
        config_file = get_config_http_file(path_to_project, project_name, virtual_env_path)

        # Writte the file to destination
        sites_available_path = '/etc/apache2/sites-available/'
        file_path = '{0}{1}'.format(sites_available_path, apache_config_file_name)

        with open(file_path, 'w') as FILE:
            for line in config_file:
                FILE.write(line)


if __name__ == '__main__':
    main()
