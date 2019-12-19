"""tests"""

load("@com_github_ali5h_rules_pip//:defs.bzl", "py_pytest_test")
load("@piptool_deps_tests_3//:requirements.bzl", "requirement")

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
