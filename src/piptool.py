import argparse
import logging
import os
import re
import sys
from collections import OrderedDict

from pip._internal.network.session import PipSession
from pip._internal.req.constructors import install_req_from_parsed_requirement
from pip._internal.req.req_file import parse_requirements

import whl


def clean_name(name):
    # Escape any illegal characters with underscore.
    return re.sub("[-.+]", "_", name)


def is_pinned_requirement(req, editable):
    """
    Returns whether a Requirement is a "pinned" requirement.
    A Requirement is considered pinned if:
    - Is not editable
    - It has exactly one specifier
    - That specifier is "=="
    - The version does not contain a wildcard
    Examples:
        django==1.8   # pinned
        django>1.8    # NOT pinned
        django~=1.8   # NOT pinned
        django==1.*   # NOT pinned
    """
    if editable:
        return False

    if len(req.specifier._specs) != 1:
        return False

    op, version = next(iter(req.specifier._specs))._spec
    return (op == "==" or op == "===") and not version.endswith(".*")


def as_tuple(preq):
    """
    Pulls out the (name: str, version:str, extras:(str)) tuple from
    the pinned ParsedRequirement.
    """
    req = install_req_from_parsed_requirement(preq)
    if not is_pinned_requirement(req, preq.is_editable):
        raise TypeError(
            (
                "Expected a pinned requirement, got {}, "
                "either pre-compile the requirements, or set compile=True in pip_import"
            ).format(req)
        )

    name = req.name
    version = next(iter(req.specifier._specs))._spec[1]
    extras = tuple(sorted(req.extras))
    return name, version, extras


def repository_name(repo_prefix, name, version, python_version):
    """Returns the canonical name of the Bazel repository for a package.

    Args:
        repo_prefix: prefix to attach to the repo
        name: package name
        version: package version
        python_version: python major version
    Returns:
     str: repo name
    """
    canonical = "__{}__{}_{}".format(python_version, name, version)
    return "{}{}".format(repo_prefix, clean_name(canonical))


def whl_library(
    name,
    extras,
    repo_name,
    pip_repo_name,
    python_interpreter,
    timeout,
    quiet,
    req_to_overrides,
):
    """Generate whl_library snippets for a package and its extras.

    Args:
        name: package nane
        extras: extras for this lib
        repo_name: repo name used for this lib
        pip_repo_name: pip_import repo
        python_interpreter:
        timeout: timeout for pip actions
        quiet: makes command run in quiet mode
        req_to_overrides: map from requirement to replacement label
    Returns:
      str: whl_library rule definition
    """
    # Indentation here matters
    return """
  if "{repo_name}" not in native.existing_rules():
    whl_library(
        name = "{repo_name}",
        pkg = "{name}",
        requirements_repo = "@{pip_repo_name}",
        python_interpreter = "{python_interpreter}",
        extras = [{extras}],
        pip_args = pip_args,
        timeout = {timeout},
        quiet = {quiet},
        overrides = {overrides},
    )""".format(
        name=name,
        repo_name=repo_name,
        pip_repo_name=pip_repo_name,
        python_interpreter=python_interpreter.replace("\\", "/"),
        extras=",".join(['"%s"' % extra for extra in extras]),
        timeout=timeout,
        quiet=quiet,
        overrides={label: req for req, label in req_to_overrides.items()},
    )


def get_requirements(requirement):
    """Parse a requirement file.

    Args:
        requirement: path to requirement file
    Returns:
        list[InstallRequirements]: list of InstallRequirement
    """
    session = PipSession()
    return parse_requirements(requirement, session=session)


def main():
    logging.basicConfig()
    parser = argparse.ArgumentParser(
        description="Import Python dependencies into Bazel."
    )
    parser.add_argument("--name", action="store", help=("The namespace of the import."))
    parser.add_argument(
        "--input",
        action="store",
        help="The requirements.txt file to import.",
        required=True,
    )
    parser.add_argument(
        "--output",
        action="store",
        help="The requirements.bzl file to export.",
        required=True,
    )
    parser.add_argument(
        "--repo-prefix",
        action="store",
        help="The prefix to add to the repository name for bazel.",
        type=str,
        required=True,
    )
    parser.add_argument(
        "--timeout",
        help="Timeout used for pip actions.",
        type=int,
        required=True,
    )
    parser.add_argument(
        "--quiet",
        help="Make pip install action quiet.",
        type=bool,
        required=True,
    )
    parser.add_argument(
        "--override",
        action="append",
        default=[],
        help="Specified to replace pip dependencies with bazel targets. Example: "
        + "--override=@com_google_protobuf//:protobuf_python=protobuf",
    )
    args = parser.parse_args()

    reqs = sorted(get_requirements(args.input), key=as_tuple)
    # args.overrides is label=req, we want {req: label}
    req_to_overrides = dict(tuple(reversed(rep.split("="))) for rep in args.override)
    python_version = "%d%d" % (sys.version_info[0], sys.version_info[1])
    whl_targets = OrderedDict()
    whl_libraries = []
    for req in reqs:
        name, version, extras = as_tuple(req)
        repo_name = repository_name(args.repo_prefix, name, version, python_version)
        if name in req_to_overrides:
            # No whl_library is created, and no extras for overrides.
            whl_targets["%s" % name] = req_to_overrides[name]
        else:
            whl_targets["%s" % name] = "@%s//:pkg" % repo_name
            # For every extra that is possible from this requirements.txt
            for extra in extras:
                whl_targets["%s[%s]" % (name, extra)] = "@%s//:%s" % (repo_name, extra)

            whl_libraries.append(
                whl_library(
                    name,
                    extras,
                    repo_name,
                    args.name,
                    sys.executable,
                    args.timeout,
                    args.quiet,
                    req_to_overrides,
                )
            )

    mappings = ",\n  ".join(
        '"%s": "%s"' % (name, target) for name, target in whl_targets.items()
    )

    with open(args.output, "w") as _f:
        _f.write(
            """\
# Install pip requirements.

load("@com_github_ali5h_rules_pip//:defs.bzl", "whl_library")

def pip_install(pip_args=[]):
  {whl_libraries}

_requirements = {{
  {mappings}
}}

all_requirements = _requirements.values()

def requirement(name, target=None):
  name_key = name.lower()
  if name_key not in _requirements:
    return name_key + "_not_found_in_requirements"
  req = _requirements[name_key]
  if target != None:
    pkg, _, _ = req.partition("//")
    req = pkg + target
  return req

def entry_point(name, entry_point=None):
  entry_point = entry_point or name
  return requirement(name, "//:{entry_point_prefix}" + entry_point)
""".format(
                entry_point_prefix=whl.ENTRYPOINT_PREFIX,
                whl_libraries="\n".join(whl_libraries),
                mappings=mappings,
            )
        )

    with open(os.path.join(os.path.dirname(args.output), "BUILD"), "w") as _f:
        _f.write(
            """# Generated BUILD file
[alias(name=name, actual=pkg,  visibility=["//visibility:public"]) for name, pkg in {{
  {mappings}
}}.items()]
""".format(
                mappings=mappings
            )
        )


if __name__ == "__main__":
    main()
