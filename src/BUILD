package(default_visibility = ["//visibility:public"])

load("@subpar//:subpar.bzl", "par_binary")

py_library(
    name = "whllib",
    srcs = ["whl.py"],
    deps = [
        "//third_party/py:pypi_vendor",
    ],
)

par_binary(
    name = "whl",
    srcs = ["whl.py"],
    python_version = "PY3",
    deps = [
        ":whllib",
    ],
)

par_binary(
    name = "piptool",
    srcs = ["piptool.py"],
    python_version = "PY3",
    deps = [
        "//third_party/py:pypi_vendor",
    ],
)

par_binary(
    name = "compile",
    srcs = ["compile.py"],
    python_version = "PY3",
    deps = [
        "//third_party/py:pypi_vendor",
    ],
)

py_library(
    name = "pytest_helper",
    srcs = ["pytest_helper.py"],
)
