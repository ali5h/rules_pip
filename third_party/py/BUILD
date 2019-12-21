py_library(
    name = "pypi_vendor",
    srcs = glob(["**/*.py"]),
    data = glob(
        ["**/*"],
        exclude = [
            "**/*.py",
            "**/*.pyc",
            "**/* *",
            "BUILD",
            "WORKSPACE",
            "bin/*",
            "__pycache__",
        ],
    ),
    imports = [""],
    visibility = ["//visibility:public"],
)
