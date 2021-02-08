PYTHON_COPTS = [
    "-fPIC",
    %{CFLAGS}
]

PYTHON_LINKOPTS = [
    %{LDFLAGS}
]

EXTENSION_SUFFIX = "%{EXTENSION_SUFFIX}"

HEADERS =  "@%{CPYTHON}//:python_headers"

def py_extension(name, **kwargs):
    extension_name = name + ".so"
    copts = kwargs.pop('copts', []) + PYTHON_COPTS
    linkopts = kwargs.pop('linkopts', []) + PYTHON_LINKOPTS
    deps = kwargs.pop('deps', []) + [HEADERS]
    native.cc_binary(
        name = extension_name,
        copts = copts,
        deps = deps,
        linkopts = linkopts,
        linkshared = True,
        linkstatic = kwargs.pop('linkstatic', True),
        **kwargs,
    )
    native.py_library(
        name = name,
        data = [extension_name],
    )
