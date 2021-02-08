licenses(["restricted"])

package(default_visibility = ["//visibility:public"])

cc_library(
    name = "python_headers",
    hdrs = glob(["include/**/*.h"]),
    includes = ["include"],
)
