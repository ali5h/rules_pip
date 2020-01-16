licenses(["restricted"])

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "lib",
    hdrs = glob(["include/*.h"]),
    srcs = glob([
        "lib/*.a",
        "lib/*.so",
    ]),
    includes = ["include"],
)