import sys

import pytest


def run(argv=None):
    args = sys.argv
    return pytest.main(args)


if __name__ == "__main__":
    sys.exit(run())
