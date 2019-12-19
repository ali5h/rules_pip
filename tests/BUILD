"""tests"""

load("//:defs.bzl", "py_pytest_test")
load("@piptool_deps_tests_3//:requirements.bzl", "requirement")

py_test(
    name = "whl_test",
    srcs = ["test_whl.py"],
    data = [
        "@futures_2_2_0_whl//file",
        "@futures_3_1_1_whl//file",
        "@google_cloud_language_whl//file",
        "@grpc_whl//file",
        "@mock_whl//file",
    ],
    main = "test_whl.py",
    python_version = "PY3",
    deps = [
        "//src:whllib",
        requirement("mock"),
        # not need, just here for testing it can be installed
        requirement("pytest"),
    ],
)

# run the test using pytest
py_pytest_test(
    name = "test_import",
    srcs = ["test_import.py"],
    python_version = "PY3",
    deps = [
        requirement("pytest"),
        requirement("google-cloud-language"),
        requirement("azure-storage-blob"),
        # to test metadata parsing
        requirement("python-dateutil"),
    ],
)
