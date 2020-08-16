licenses(["restricted"])

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "lib",
    srcs = glob([
        "lib/*.a",
        "lib/*.so",
    ]),
    hdrs = glob(["include/**/*.h"]),
    includes = ["include"],
)
