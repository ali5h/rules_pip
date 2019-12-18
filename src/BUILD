load("@piptool_deps//:requirements.bzl", "requirement")

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

py_library(
    name = "pytest_helper",
    srcs = ["pytest_helper.py"],
)
