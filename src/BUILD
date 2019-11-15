package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_binary")
load("@piptool_deps//:requirements.bzl", "requirement")
load("@piptool_deps_3//:requirements.bzl", requirement_3 = "requirement")
load("@subpar//:subpar.bzl", "par_binary")

py_library(
    name = "common",
    srcs = ["common.py"],
)

py_library(
    name = "whllib",
    srcs = ["whl.py"],
    deps = [":common"] + select(
        {
            "@bazel_tools//tools/python:PY2": [
                requirement("pip"),
                requirement("pkginfo"),
                requirement("setuptools"),
                requirement("wheel"),
            ],
            "@bazel_tools//tools/python:PY3": [
                requirement_3("pip"),
                requirement_3("pkginfo"),
                requirement_3("setuptools"),
                requirement_3("wheel"),
            ],
        },
    ),
)

par_binary(
    name = "whl",
    srcs = ["whl.py"],
    python_version = "PY2",
    zip_safe = False,
    deps = [
        ":whllib",
    ],
)

par_binary(
    name = "piptool",
    srcs = ["piptool.py"],
    python_version = "PY2",
    deps = [
        requirement("pip"),
    ],
)

par_binary(
    name = "compile",
    srcs = ["compile.py"],
    python_version = "PY2",
    zip_safe = False,
    deps = [
        ":common",
        requirement("pip-tools"),
        requirement("pip"),
        requirement("setuptools"),
        requirement("wheel"),
    ],
)

py_library(
    name = "pytest_helper",
    srcs = ["pytest_helper.py"],
)
