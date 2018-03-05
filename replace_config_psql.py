import sys
import os

if len(sys.argv) < 2:
    pass
else:
    path = '/etc/postgresql/' + sys.argv[1] + '/main/pg_hba.conf'
    additional_line = 'local   all             all                                     md5\n'

    new_lines = []
    header_found = False
    pass_one = False

    with open(path) as FILE:
        for line in FILE:
            if header_found and line == additional_line:
               
            if pass_one:
                pass_one = False
                continue

            if line == '''# "local" is for Unix domain socket connections only\n''':
                header_found = True
                os.system("echo done")
                new_lines.append(line)
                new_lines.append(additional_line)
                pass_one = True
            else:
                new_lines.append(line)
 
    with open(path, 'w') as CONFIG_FILE:
        for line in new_lines:
            CONFIG_FILE.write(line)
            CONFIG_FILE.close()

