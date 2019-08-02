import argparse
import glob
import os
import zipfile

import pkg_resources
import pkginfo
from pip._internal.commands import WheelCommand


def download_whl(pkg, directory, constraint):
    """Downloads wheel for a package

    :param pkg:
    :param directory:
    :param pip_args:
    :returns:
    :rtype:

    """
    cmd = WheelCommand()
    args = ["--wheel-dir", directory, "--no-deps", "--constraint", constraint]
    args += [pkg]
    cmd.run(*cmd.parse_args(args))
    return glob.glob(os.path.join(directory, "*.whl"))[0]


def expand(whl_path, directory):
    """Expands a wheel into a directory

    :param whl_path: path to wheel file
    :param directory: destination

    """
    with zipfile.ZipFile(whl_path, "r") as whl:
        whl.extractall(directory)


def dependencies(whl_path, extra=None):
    pkg = pkginfo.Wheel(whl_path)
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
        help="Extra args passed to pip. (e.g. --pip-arg={'-c','reqs.txt'}",
        required=True,
    )
    parser.add_argument(
        "--extras",
        action="append",
        help="The set of extras for which to generate library targets.",
    )

    args = parser.parse_args()
    whl_path = download_whl(args.package, args.directory, args.constraint)

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
                    ['requirement("%s")' % d for d in dependencies(whl_path, extra)]
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
    data = glob(["**/*"], exclude=["**/*.py", "**/*.pyc", "**/* *", "BUILD", "WORKSPACE"]),
    # This makes this directory a top-level in the python import
    # search path for anything that depends on this.
    imports = ["."],
    deps = [
        {dependencies}
    ],
)
{extras}""".format(
        requirements=args.requirements,
        dependencies=",".join(
            ['requirement("%s")' % d for d in dependencies(whl_path)]
        ),
        extras=extras,
    )

    expand(whl_path, args.directory)
    with open(os.path.join(args.directory, "BUILD"), "w") as f:
        f.write(result)


if __name__ == "__main__":
    main()
