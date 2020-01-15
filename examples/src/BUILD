load("@io_bazel_rules_docker//python3:image.bzl", "py3_image")
load("@piptool_deps_tests_3//:requirements.bzl", "requirement")

py3_image(
    name = "main_image",
    srcs = ["main.py"],
    main = "main.py",
    deps = [
        requirement("google-cloud-language"),
    ],
)
