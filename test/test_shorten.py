"""Tests for py/shorten_path_for_notational_fzf.py."""
import os
import re
import subprocess
import sys
import tempfile
import unittest

SCRIPT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                      'py', 'shorten_path_for_notational_fzf.py')


def run(data: bytes, cwd: str) -> list:
    out = subprocess.run([sys.executable, '-S', SCRIPT], input=data, cwd=cwd,
                         capture_output=True, check=False).stdout
    return out.decode('utf-8', 'replace').splitlines()


def strip(line: str) -> str:
    return re.sub('\x1b\\[[0-9;]*m', '', line)


class ShortenTest(unittest.TestCase):
    def setUp(self):
        self.tmp = os.path.realpath(tempfile.mkdtemp())
        self.cwd = os.path.join(self.tmp, 'zk')
        os.mkdir(self.cwd)

    def test_format(self):
        path = os.path.join(self.cwd, 'sub', 'note.md')
        lines = [strip(x) for x in run(f'{path}:3:some: text\n'.encode(), self.cwd)]
        self.assertEqual([f'{path}:3:s/note.md:3:some: text'], lines)

    def test_path_outside_home_and_cwd(self):
        lines = [strip(x) for x in run(b'/a.md:1:x\n', self.cwd)]
        self.assertEqual(['/a.md:1:/a.md:1:x'], lines)

    def test_sibling_directory_is_not_taken_for_current(self):
        path = os.path.join(self.tmp, 'zk2', 'note.md')
        lines = [strip(x) for x in run(f'{path}:1:x\n'.encode(), self.cwd)]
        self.assertEqual([f'{path}:1:../z/note.md:1:x'], lines)

    def test_line_without_line_number_is_kept(self):
        path = os.path.join(self.cwd, 'a.md')
        lines = [strip(x) for x in run(f'{path}:x\n{path}:1:y\n'.encode(), self.cwd)]
        self.assertEqual(2, len(lines))


if __name__ == '__main__':
    unittest.main()
