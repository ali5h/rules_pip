package(default_visibility = ["//visibility:public"])

load("@rules_python//python:defs.bzl", "py_binary",  "py_test")
load("@piptool_deps//:requirements.bzl", "requirement")

py_binary(
    name = "whl",
    srcs = ["whl.py"],
    deps = [
        ":piptool",
        requirement("pip"),
        requirement("pkginfo"),
    ],
    python_version="PY2",
)

py_test(
    name = "whl_test",
    srcs = ["whl_test.py"],
    data = [
        "@futures_3_1_1_whl//file",
        "@futures_2_2_0_whl//file",
        "@google_cloud_language_whl//file",
        "@grpc_whl//file",
        "@mock_whl//file",
    ],
    deps = [
        ":whl",
        requirement("mock"),
    ],
    python_version="PY2",
)

py_binary(
    name = "piptool",
    srcs = ["piptool.py"],
    deps = [
        requirement("pip"),
    ],
    python_version="PY2",
)

