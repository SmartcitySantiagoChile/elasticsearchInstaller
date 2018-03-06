# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import sys


def getConfiguration(startServers=2, minSpareThreads=25, maxSpareThreads=75, threadLimit=64, threadsPerChild=25,
                     maxRequestWorkers=150, maxConnectionsPerChild=0):
    return '''# worker MPM
# StartServers: initial number of server processes to start
# MinSpareThreads: minimum number of worker threads which are kept spare
# MaxSpareThreads: maximum number of worker threads which are kept spare
# ThreadLimit: ThreadsPerChild can be changed to this maximum value during a
#			  graceful restart. ThreadLimit can only be changed by stopping
#			  and starting Apache.
# ThreadsPerChild: constant number of worker threads in each server process
# MaxRequestWorkers: maximum number of threads
# MaxConnectionsPerChild: maximum number of requests a server process serves
<IfModule mpm_worker_module>
	StartServers			 {0}
	MinSpareThreads		 {1}
	MaxSpareThreads		 {2}
	ThreadLimit			 {3}
	ThreadsPerChild		 {4}
	MaxRequestWorkers	  {5}
	MaxConnectionsPerChild   {6}
</IfModule>
# vim: syntax=apache ts=4 sw=4 sts=4 sr noet'''.format(startServers, minSpareThreads, maxSpareThreads, threadLimit,
                                                       threadsPerChild, maxRequestWorkers, maxConnectionsPerChild)


def main():
    if len(sys.argv) < 8:
        pass
    else:
        config_file = getConfiguration(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6],
                                       sys.argv[7])

        # It writes the file to destination
        path = '/etc/apache2/mods-available/mpm_worker.conf'

        with open(path, 'w') as FILE:
            for line in config_file:
                FILE.write(line)


if __name__ == '__main__':
    main()
