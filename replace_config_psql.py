# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import sys
import os


def update_pg_hba_file(postgresql_version):
    path = '/etc/postgresql/{0}/main/pg_hba.conf'.format(postgresql_version)
    additional_line = 'local   all             all                                     md5\n'

    new_lines = []
    header_found = False

    with open(path) as FILE:
        for line in FILE:
            if header_found and line != additional_line:
                # if additional line was added previously, ignore it
                new_lines.append(additional_line)
                os.system("echo done")

            if line == '''# "local" is for Unix domain socket connections only\n''':
                header_found = True

            new_lines.append(line)

    with open(path, 'w') as CONFIG_FILE:
        for line in new_lines:
            CONFIG_FILE.write(line)


def main():
    if len(sys.argv) < 2:
        pass
    else:
        update_pg_hba_file(sys.argv[1])


if __name__ == "__main__":
    main()
