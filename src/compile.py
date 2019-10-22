from piptools.scripts import compile

from src.common import update_python_path

if __name__ == "__main__":  # pragma: no branch
    update_python_path(["pip", "setuptools", "wheel"])
    compile.cli()
