import os
import sys

def update_python_path(packages):
    """Add a specific package path to PYTHONPATH. This is needed since pip
    commands are usually called as separate processes.

    :param packages: list of package names

    """
    to_add = [
        path for path in sys.path for package in packages if package in path
    ]
    existing_pythonpath = os.environ.get('PYTHONPATH')
    if existing_pythonpath:
        to_add.extend(existing_pythonpath.split(':'))
    os.environ['PYTHONPATH'] = ':'.join(to_add)
