# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import sys


def main():
    if len(sys.argv) < 3:
        pass
    else:
        path_project = sys.argv[1]
        project_name = sys.argv[2]
        wsgi_file_path = '{0}/{1}/{1}/wsgi.py'.format(path_project, project_name)

        new_lines = []

        with open(wsgi_file_path, 'r') as FILE:
            for line in FILE:
                if 'sys.path.append' in line:
                    new_lines.append('sys.path.append(\'{0}/{1}\')\n'.format(path_project, project_name))
                else:
                    new_lines.append(line)

        with open(wsgi_file_path, 'w') as FILE:
            for line in new_lines:
                FILE.write(line)


if __name__ == '__main__':
    main()
