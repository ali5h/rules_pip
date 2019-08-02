package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_binary", "py_test")
load("@piptool_deps//:requirements.bzl", "requirement")
load("@subpar//:subpar.bzl", "par_binary")

par_binary(
    name = "whl",
    srcs = ["whl.py"],
    python_version = "PY2",
    deps = [
        requirement("pip"),
        requirement("pkginfo"),
        requirement("wheel"),
    ],
)

py_test(
    name = "whl_test",
    srcs = ["whl_test.py"],
    data = [
        "@futures_2_2_0_whl//file",
        "@futures_3_1_1_whl//file",
        "@google_cloud_language_whl//file",
        "@grpc_whl//file",
        "@mock_whl//file",
    ],
    python_version = "PY2",
    deps = [
        ":whl",
        requirement("mock"),
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
