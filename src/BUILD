load("@piptool_deps//:requirements.bzl", "requirement")
load("@subpar//:subpar.bzl", "par_binary")

package(default_visibility = ["//visibility:public"])

py_library(
    name = "common",
    srcs = ["common.py"],
)

py_library(
    name = "whllib",
    srcs = ["whl.py"],
    deps = [
        ":common",
        requirement("pip"),
        requirement("pkginfo"),
        requirement("setuptools"),
        requirement("wheel"),
    ],
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
