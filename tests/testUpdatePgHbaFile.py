# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from unittest import TestCase

from replace_config_psql import update_pg_hba_file

import os


class TestFileUpdater(TestCase):

    def setUp(self):
        # create file
        self.file_name = 'test.test'
        self.file_path = '{0}'.format(self.file_name)

    def create_file(self, content=''):
        with open(self.file_name, 'w') as test_file:
            test_file.write(content)

    def delete_file(self):
        os.remove(self.file_name)

    def test_process_file_without_match(self):
        content = ''

        self.create_file(content)

        update_pg_hba_file('', self.file_path)

        self.assertEqual(open(self.file_name).read(), content)

        self.delete_file()

    def test_process_file_with_match(self):
        meta_content = '# "local" is for Unix domain socket connections only\n{0}\n'
        content = meta_content.format('')
        new_content = meta_content.format('local   all             all                                     md5\n')

        self.create_file(content)

        update_pg_hba_file('', self.file_path)

        self.assertEqual(open(self.file_name).read(), new_content)

        self.delete_file()

    def test_process_file_with_match_but_line_exists(self):
        meta_content = '# "local" is for Unix domain socket connections only\n{0}\n'
        additional_line = 'local   all             all                                     md5\n'
        content = meta_content.format(additional_line)
        new_content = meta_content.format(additional_line)

        self.create_file(content)

        update_pg_hba_file('', self.file_path)

        self.assertEqual(open(self.file_name).read(), new_content)

        self.delete_file()
