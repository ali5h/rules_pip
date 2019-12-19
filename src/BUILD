load("//:requirements.bzl", "requirement")

package(default_visibility = ["//visibility:public"])

py_library(
    name = "whllib",
    srcs = ["whl.py"],
    deps = [
        requirement("pip"),
        requirement("pkginfo"),
        requirement("setuptools"),
        requirement("wheel"),
    ],
)

py_binary(
    name = "whl",
    srcs = ["whl.py"],
    python_version = "PY3",
    deps = [
        ":whllib",
    ],
)

py_binary(
    name = "piptool",
    srcs = ["piptool.py"],
    python_version = "PY3",
    deps = [
        requirement("pip"),
    ],
)

py_binary(
    name = "compile",
    srcs = ["compile.py"],
    python_version = "PY3",
    deps = [
        requirement("pip-tools"),
    ],
)

py_library(
    name = "pytest_helper",
    srcs = ["pytest_helper.py"],
)
