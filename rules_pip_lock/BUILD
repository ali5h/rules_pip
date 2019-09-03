package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_binary", "py_test")
load("@piptool_deps//:requirements.bzl", "requirement")
load("@piptool_deps_3//:requirements.bzl", requirement_3 = "requirement")
load("@subpar//:subpar.bzl", "par_binary")

py_library(
    name = "whllib",
    srcs = ["whl.py"],
    deps = select(
        {
            "@bazel_tools//tools/python:PY2": [
                requirement("pip"),
                requirement("pkginfo"),
                requirement("setuptools"),
            ],
            "@bazel_tools//tools/python:PY3": [
                requirement_3("pip"),
                requirement_3("pkginfo"),
                requirement_3("setuptools"),
            ],
        },
    ),
)

par_binary(
    name = "whl",
    srcs = ["whl.py"],
    python_version = "PY2",
    deps = [
        requirement("pip"),
        requirement("pkginfo"),
        requirement("setuptools"),
    ],
)

py_test(
    name = "whl_test2",
    srcs = ["whl_test.py"],
    data = [
        "@futures_2_2_0_whl//file",
        "@futures_3_1_1_whl//file",
        "@google_cloud_language_whl//file",
        "@grpc_whl//file",
        "@mock_whl//file",
    ],
    main = "whl_test.py",
    python_version = "PY2",
    deps = [
        ":whllib",
        requirement("mock"),
    ],
)

py_test(
    name = "whl_test3",
    srcs = ["whl_test.py"],
    data = [
        "@futures_2_2_0_whl//file",
        "@futures_3_1_1_whl//file",
        "@google_cloud_language_whl//file",
        "@grpc_whl//file",
        "@mock_whl//file",
    ],
    main = "whl_test.py",
    python_version = "PY3",
    deps = [
        ":whllib",
        requirement_3("mock"),
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
    deps = [
        requirement("pip-tools"),
    ],
)
