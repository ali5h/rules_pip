# Install pip requirements.

load("//:defs.bzl", "whl_library")

def pip_install(pip_args = []):
    if "pypi__27__click_7_0" not in native.existing_rules():
        whl_library(
            name = "pypi__27__click_7_0",
            pkg = "click",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__funcsigs_1_0_2" not in native.existing_rules():
        whl_library(
            name = "pypi__27__funcsigs_1_0_2",
            pkg = "funcsigs",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__mock_3_0_5" not in native.existing_rules():
        whl_library(
            name = "pypi__27__mock_3_0_5",
            pkg = "mock",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__pip_tools_4_3_0" not in native.existing_rules():
        whl_library(
            name = "pypi__27__pip_tools_4_3_0",
            pkg = "pip-tools",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__pkginfo_1_5_0_1" not in native.existing_rules():
        whl_library(
            name = "pypi__27__pkginfo_1_5_0_1",
            pkg = "pkginfo",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__six_1_13_0" not in native.existing_rules():
        whl_library(
            name = "pypi__27__six_1_13_0",
            pkg = "six",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__wheel_0_33_6" not in native.existing_rules():
        whl_library(
            name = "pypi__27__wheel_0_33_6",
            pkg = "wheel",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__pip_19_2_3" not in native.existing_rules():
        whl_library(
            name = "pypi__27__pip_19_2_3",
            pkg = "pip",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

    if "pypi__27__setuptools_42_0_2" not in native.existing_rules():
        whl_library(
            name = "pypi__27__setuptools_42_0_2",
            pkg = "setuptools",
            requirements_repo = "@piptool_deps",
            python_interpreter = "/usr/bin/python2.7",
            extras = [],
            pip_args = pip_args,
        )

_requirements = {
    "click": "@pypi__27__click_7_0//:pkg",
    "funcsigs": "@pypi__27__funcsigs_1_0_2//:pkg",
    "mock": "@pypi__27__mock_3_0_5//:pkg",
    "pip-tools": "@pypi__27__pip_tools_4_3_0//:pkg",
    "pkginfo": "@pypi__27__pkginfo_1_5_0_1//:pkg",
    "six": "@pypi__27__six_1_13_0//:pkg",
    "wheel": "@pypi__27__wheel_0_33_6//:pkg",
    "pip": "@pypi__27__pip_19_2_3//:pkg",
    "setuptools": "@pypi__27__setuptools_42_0_2//:pkg",
}

def requirement(name):
    name_key = name.lower()
    if name_key not in _requirements:
        fail("Could not find pip-provided dependency: '%s'" % name)
    return _requirements[name_key]
