"""downloads and parses info of a pkg and generates a BUILD file for it"""
import argparse
import glob
import logging
import os
import shutil
import sys

from pip._internal.commands import create_command
from pip._vendor import pkg_resources

import pkginfo
import installer

ENTRYPOINT_PREFIX = "bin-"

# https://github.com/dillon-giacoppo/rules_python_external/blob/master/tools/wheel_wrapper.py
def configure_reproducible_wheels():
    """
    Wheels created from sdists are not reproducible by default. We can
    however workaround this by patching in some configuration with
    environment variables.
    """

    # wheel, by default, enables debug symbols in GCC. This incidentally
    # captures the build path in the .so file We can override this
    # behavior by disabling debug symbols entirely.
    # https://github.com/pypa/pip/issues/6505
    if os.environ.get("CFLAGS") is not None:
        os.environ["CFLAGS"] += " -g0"
    else:
        os.environ["CFLAGS"] = "-g0"

    # set SOURCE_DATE_EPOCH to 1980 so that we can use python wheels
    # https://github.com/NixOS/nixpkgs/blob/master/doc/languages-frameworks/python.section.md#python-setuppy-bdist_wheel-cannot-create-whl
    if os.environ.get("SOURCE_DATE_EPOCH") is None:
        os.environ["SOURCE_DATE_EPOCH"] = "315532800"

    # Python wheel metadata files can be unstable.
    # https://bitbucket.org/pypa/wheel/pull-requests/74/make-the-output-of-metadata-files/diff
    if os.environ.get("PYTHONHASHSEED") is None:
        os.environ["PYTHONHASHSEED"] = "0"


def _create_nspkg_init(dirpath):
    """Creates an init file to enable namespacing"""
    if not os.path.exists(dirpath):
        # Handle missing namespace packages by ignoring them
        return
    nspkg_init = os.path.join(dirpath, "__init__.py")
    with open(nspkg_init, "w") as nspkg:
        nspkg.write("__path__ = __import__('pkgutil').extend_path(__path__, __name__)")


def install_package(pkg, directory, pip_args):
    """Downloads wheel for a package. Assumes python binary provided has
    pip and wheel package installed.

    Args:
        pkg: package name
        directory: destination directory to download the wheel file in
        python: python binary path used to run pip command
        pip_args: extra pip args sent to pip
    Returns:
        str: path to the wheel file
    """
    pip_args = [
        "--isolated",
        "--disable-pip-version-check",
        "--target",
        directory,
        "--no-deps",
        "--ignore-requires-python",
        "--use-deprecated=legacy-resolver",
        pkg,
    ] + pip_args
    cmd = create_command("install")
    cmd.main(pip_args)

    # need dist-info directory for pkg_resources to be able to find the packages
    dist_info = glob.glob(os.path.join(directory, "*.dist-info"))[0]
    # fix namespace packages by adding proper __init__.py files
    namespace_packages = os.path.join(dist_info, "namespace_packages.txt")
    if os.path.exists(namespace_packages):
        with open(namespace_packages) as nspkg:
            for line in nspkg.readlines():
                namespace = line.strip().replace(".", os.sep)
                if namespace:
                    _create_nspkg_init(os.path.join(directory, namespace))

    # PEP 420 -- Implicit Namespace Packages
    if (sys.version_info[0], sys.version_info[1]) >= (3, 3):
        for dirpath, dirnames, filenames in os.walk(directory):
            # we are only interested in dirs with no init file
            if "__init__.py" in filenames:
                dirnames[:] = []
                continue
            # remove bin and dist-info dirs
            for ignored in ("bin", os.path.basename(dist_info)):
                if ignored in dirnames:
                    dirnames.remove(ignored)
            _create_nspkg_init(dirpath)

    return pkginfo.Wheel(dist_info)


def dependencies(pkg, extra=None):
    """Find dependencies of a wheel.

    Args:
        whl_path: path to wheel
        extra: find additional dependencies for the extra instead
    Returns:
        list: list of dependencies
    """
    ret = set()
    for dist in pkg.requires_dist:
        requirement = pkg_resources.Requirement.parse(dist)
        # we replace all underscores with dash, to make package names similiar in all cases
        name = requirement.name.replace("_", "-")
        if extra:
            # for extras we don't grab dependencies for the main pkg,
            # those are already in the main plg rule
            if not requirement.marker or requirement.marker.evaluate({"extra": None}):
                continue

        if requirement.marker:
            if not requirement.marker.evaluate({"extra": extra}):
                continue

        if requirement.extras:
            ret = ret | set(
                ["{}[{}]".format(name, dist_extra) for dist_extra in requirement.extras]
            )
        else:
            ret.add(name)

    return sorted(list(ret))


def _cleanup(directory, pattern):
    for p in glob.glob(os.path.join(directory, pattern)):
        shutil.rmtree(p)


def _get_numpy_headers(directory):
    """Generate cc_library rule for numpy headers.

    Args:
        directory: path to numpy package installation root
    Returns:
        str: a cc_library rule
    """
    sys.path.insert(0, directory)
    import numpy

    include_dir = os.path.relpath(numpy.get_include(), directory)
    sys.path.pop(0)
    return """
cc_library(
    name = "headers",
    hdrs = glob(["{include_dir}/**/*.h"]),
    includes = ["{include_dir}"],
)
""".format(
        include_dir=include_dir
    )


def get_entry_points(directory):
    dist_info = glob.glob(os.path.join(directory, "*.dist-info"))[0]
    entry_points_path = os.path.join(dist_info, "entry_points.txt")
    entry_points_mapping = {}
    if not os.path.exists(entry_points_path):
        return entry_points_mapping

    with open(entry_points_path) as f:
        entry_points = installer.utils.parse_entrypoints(f.read())
        for script, module, attribute, script_section in entry_points:
            if script_section == "console":
                entry_points_mapping[script] = (module, attribute)
        return entry_points_mapping


def main():
    logging.basicConfig()
    parser = argparse.ArgumentParser(
        description="Create py_library rule for a WHL file."
    )
    parser.add_argument(
        "--package", action="store", help=("The package name. This is passed to pip.")
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
        "--extras",
        action="append",
        help="The set of extras for which to generate library targets.",
    )
    parser.add_argument(
        "--override",
        action="append",
        default=[],
        help="Specified to replace pip dependencies with bazel targets. Example: "
        + "--override=@com_google_protobuf//:protobuf_python=protobuf",
    )

    args, pip_args = parser.parse_known_args()

    pip_args += ["-c", args.constraint]

    configure_reproducible_wheels()

    pkg = install_package(args.package, args.directory, pip_args)
    extras_list = [
        """
py_library(
    name = "{extra}",
    deps = [
        ":pkg",{deps}
    ],
)""".format(
            extra=extra,
            deps=",".join(['requirement("%s")' % d for d in dependencies(pkg, extra)]),
        )
        for extra in args.extras or []
    ]

    entry_point_list = [
        """
genrule(
    name = "{entrypoint_prefix}copy_{script}",
    srcs = ["bin/{script}"],
    outs = ["bin/{entrypoint_prefix}{script}.py"],
    cmd = "cp $(SRCS) $(OUTS)",
)

py_binary(
    name = "{entrypoint_prefix}{script}",
    srcs = ["bin/{entrypoint_prefix}{script}.py"],
    main = "bin/{entrypoint_prefix}{script}.py",
    imports = ["."],
    deps = [":pkg"],
)
""".format(
            entrypoint_prefix=ENTRYPOINT_PREFIX, script=script
        )
        for script, val in get_entry_points(args.directory).items()
    ]
    entry_points_str = "\n".join(entry_point_list)

    # we treat numpy in a special way, inject a rule for numpy headers
    if args.package == "numpy":
        extras_list.append(_get_numpy_headers(args.directory))

    extras = "\n".join(extras_list)
    # args.override looks like a list of replacement=requirement
    overrides = dict(rep.split("=") for rep in args.override)

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
        "__pycache__",
    ]),
    # This makes this directory a top-level in the python import
    # search path for anything that depends on this.
    imports = ["."],
    deps = [
        {dependencies}
    ],
)

filegroup(
    name = "distinfo",
    srcs = glob(["*.dist-info/**"]),
)

{entry_points}

{extras}""".format(
        requirements=args.requirements,
        dependencies=",\n        ".join(
            [
                '"%s"' % overrides[d] if d in overrides else 'requirement("%s")' % d
                for d in dependencies(pkg)
            ]
        ),
        entry_points=entry_points_str,
        extras=extras,
    )

    # clean up
    _cleanup(args.directory, "__pycache__")

    with open(os.path.join(args.directory, "BUILD"), "w") as f:
        f.write(result)


if __name__ == "__main__":
    main()
