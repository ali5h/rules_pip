"""downloads and parses info of a pkg and generates a BUILD file for it"""
import argparse
import glob
import os
import shutil
import sys

import pkginfo
import platform
from pip._internal.commands import InstallCommand
from pip._vendor import pkg_resources


def update_python_path(packages):
    to_add = [
        path for path in sys.path for package in packages if package in path
    ]
    existing_pythonpath = os.environ.get('PYTHONPATH')
    if existing_pythonpath:
        to_add.extend(existing_pythonpath.split(':'))
    os.environ['PYTHONPATH'] = ':'.join(to_add)


def install_package(pkg, directory, python_version, pip_args):
    """Downloads wheel for a package. Assumes python binary provided has
    pip and wheel package installed.

    :param pkg: package name
    :param directory: destination directory to download the wheel file in
    :param python: python binary path used to run pip command
    :param pip_args: extra pip args sent to pip
    :returns: path to the wheel file
    :rtype: str

    """
    pip_args = [
        "--isolated",
        "--disable-pip-version-check",
        "--target",
        directory,
        "--no-deps",
        "--ignore-requires-python",
        "--python-version",
        python_version,
        pkg,
    ] + pip_args
    cmd = InstallCommand()
    cmd.run(*cmd.parse_args(pip_args))

    # need dist-info directory for pkg_resources to be able to find the packages
    dist_info = glob.glob(os.path.join(directory, "*.dist-info"))[0]
    # fix namespace packages by adding proper __init__.py files
    namespace_packages = os.path.join(dist_info, "namespace_packages.txt")
    if os.path.exists(namespace_packages):
        with open(namespace_packages) as nspkg:
            for line in nspkg.readlines():
                namespace = line.strip().replace(".", os.sep)
                if namespace:
                    nspkg_init = os.path.join(directory, namespace, "__init__.py")
                    with open(nspkg_init, "w") as nspkg:
                        nspkg.write(
                            "__path__ = __import__('pkgutil').extend_path(__path__, __name__)"
                        )

    return pkginfo.Wheel(dist_info)


def dependencies(pkg, extra=None):
    """find dependencies of a wheel.

    :param whl_path: path to wheel
    :param extra: find additional dependencies for the extra instead
    :returns: list of dependencies
    :rtype: list

    """
    ret = []
    for dist in pkg.requires_dist:
        requirement = pkg_resources.Requirement.parse(dist)
        if extra:
            # for extras we don't grab dependencies for the main pkg,
            # those are already in the main plg rule
            if not requirement.marker or requirement.marker.evaluate({"extra": None}):
                continue

        if requirement.marker:
            if not requirement.marker.evaluate({"extra": extra}):
                continue

        if requirement.extras:
            ret.extend(
                "{}[{}]".format(requirement.name, dist_extra)
                for dist_extra in requirement.extras
            )
        else:
            ret.append(requirement.name)

    return ret


def _cleanup(directory, pattern):
    for p in glob.glob(os.path.join(directory, pattern)):
        shutil.rmtree(p)


def main():
    parser = argparse.ArgumentParser(
        description="Create py_library rule for a WHL file."
    )
    parser.add_argument(
        "package", action="store", help=("The package name. This is passed to pip.")
    )
    parser.add_argument(
        "--requirements",
        action="store",
        help="The pip_import from which to draw dependencies.",
    )
    parser.add_argument(
        "--directory",
        action="store",
        default=".",
        help="The directory into which to expand things.",
    )
    parser.add_argument(
        "--constraint",
        help="path to requirement file used for pip constraints",
        required=True,
    )
    parser.add_argument(
        "--pip-arg",
        action="append",
        dest="pip_args",
        help="Extra pip args. (e.g. --pip_arg={'-c','reqs.txt'}",
        default=[],
    )
    parser.add_argument(
        "--extras",
        action="append",
        help="The set of extras for which to generate library targets.",
    )
    parser.add_argument(
        "--python-version",
        help="The python version to evaluate the dependencies for",
        required=True,
    )

    args = parser.parse_args()

    platform.python_version = lambda: args.python_version

    pip_args = args.pip_args + ["-c", args.constraint]
    pkg = install_package(args.package, args.directory, args.python_version, pip_args)

    extras = "\n".join(
        [
            """
py_library(
    name = "{extra}",
    deps = [
        ":pkg",{deps}
    ],
)""".format(
                extra=extra,
                deps=",".join(
                    ['requirement("%s")' % d for d in dependencies(pkg, extra)]
                ),
            )
            for extra in args.extras or []
        ]
    )

    result = """
package(default_visibility = ["//visibility:public"])

load("{requirements}//:requirements.bzl", "requirement")

py_library(
    name = "pkg",
    srcs = glob(["**/*.py"]),
    data = glob(["**/*"], exclude = [
        "**/*.py",
        "**/*.pyc",
        "**/* *",
        "BUILD",
        "WORKSPACE",
        "bin/*",
        "__pycache__",
    ]),
    # This makes this directory a top-level in the python import
    # search path for anything that depends on this.
    imports = ["."],
    deps = [
        {dependencies}
    ],
)
{extras}""".format(
        requirements=args.requirements,
        dependencies=",".join(['requirement("%s")' % d for d in dependencies(pkg)]),
        extras=extras,
    )

    # clean up
    _cleanup(args.directory, "__pycache__")

    with open(os.path.join(args.directory, "BUILD"), "w") as f:
        f.write(result)


if __name__ == "__main__":
    update_python_path(["setuptools", "wheel"])
    main()
