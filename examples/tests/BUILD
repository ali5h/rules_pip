"""tests"""

load("@com_github_ali5h_rules_pip//:defs.bzl", "py_pytest_test")
load("@piptool_deps_tests_3//:requirements.bzl", "requirement")

# run the test using pytest
py_pytest_test(
    name = "test_import",
    srcs = ["test_import.py"],
    data = [":_test.so"],
    python_version = "PY3",
    deps = [
        requirement("pytest"),
        requirement("google-cloud-language"),
        requirement("azure-storage-blob"),
        # to test metadata parsing
        requirement("python-dateutil"),
        requirement("xgboost"),
        requirement("numpy"),
    ],
)

# using numpy headers target
cc_binary(
    name = "_test.so",
    srcs = ["test_numpy.c"],
    linkopts = [
        "-lcrypt",
        "-lpthread",
        "-ldl",
        "-lutil",
        "-lm",
    ],
    linkshared = True,
    linkstatic = False,
    deps = [
        "@cpython37//:lib",
        requirement("numpy", "//:headers"),
    ],
)
