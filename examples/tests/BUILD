"""tests"""

load("@com_github_ali5h_rules_pip//:defs.bzl", "py_pytest_test")
load("@piptool_deps_tests_3//:requirements.bzl", "requirement")
load("@cpython//:defs.bzl", "py_extension")

# run the test using pytest
py_pytest_test(
    name = "test_import",
    srcs = ["test_import.py"],
    python_version = "PY3",
    deps = [
        "_test",
        requirement("pytest"),
        requirement("google-cloud-language"),
        requirement("azure-storage-blob"),
        # to test metadata parsing
        requirement("python-dateutil"),
        requirement("xgboost"),
        # to test package alias
        "@piptool_deps_tests_3//:numpy",
    ],
)

# using numpy headers target
py_extension(
    name = "_test",
    srcs = ["test_numpy.c"],
    deps = [
        requirement("numpy", "//:headers"),
    ],
)
