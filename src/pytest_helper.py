import sys
import pytest


def run(argv=None):
    args = sys.argv + ["--ignore=external", ".", "-p", "no:cacheprovider"]
    return pytest.main(args)


if __name__ == "__main__":
    sys.exit(run())
