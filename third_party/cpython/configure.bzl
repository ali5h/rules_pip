"""Detects and configures the local Python.

Add the following to your WORKSPACE FILE:

```python
python_configure(name = "cpython37", interpreter = "python3.7")
```

Args:
  name: A unique name for this workspace rule.
  interpreter: interpreter used to config this workspace
"""

def _tpl(repository_ctx, tpl, substitutions = {}, out = None):
    if not out:
        out = tpl
    repository_ctx.template(
        out,
        Label("//third_party/cpython:%s.tpl" % tpl),
        substitutions,
    )

def _fail(msg):
    """Output failure message when auto configuration fails."""
    red = "\033[0;31m"
    no_color = "\033[0m"
    fail("%sPython Configuration Error:%s %s\n" % (red, no_color, msg))

def _execute(
        repository_ctx,
        cmdline,
        error_msg = None,
        error_details = None,
        empty_stdout_fine = False,
        environment = {}):
    """Executes an arbitrary shell command.

    Args:
      repository_ctx: the repository_ctx object
      cmdline: list of strings, the command to execute
      error_msg: string, a summary of the error if the command fails
      error_details: string, details about the error or steps to fix it
      empty_stdout_fine: bool, if True, an empty stdout result is fine, otherwise
        it's an error
      environment: environment variables passed to repository_ctx.execute

    Return:
      the result of repository_ctx.execute(cmdline)
    """
    result = repository_ctx.execute(cmdline, environment = environment)
    if result.stderr or not (empty_stdout_fine or result.stdout):
        _fail("\n".join([
            error_msg.strip() if error_msg else "Repository command failed",
            result.stderr.strip(),
            error_details if error_details else "",
        ]))
    return result

def _get_bin(repository_ctx, bin_name):
    """Gets the bin path."""
    bin_path = repository_ctx.which(bin_name)
    if bin_path != None:
        return str(bin_path)
    _fail("Cannot find %s in PATH" % bin_name)

def _get_python_include(repository_ctx, python_bin):
    """Gets the python include path."""
    result = _execute(
        repository_ctx,
        [
            python_bin,
            "-c",
            "from __future__ import print_function;" +
            "from distutils import sysconfig;" +
            "print(sysconfig.get_python_inc())",
        ],
        error_msg = "Problem getting python include path.",
    )
    return repository_ctx.path(result.stdout.splitlines()[0])

def _get_python_import_lib_path(repository_ctx, python_bin):
    """Get Python import library"""
    result = _execute(
        repository_ctx,
        [
            python_bin,
            "-c",
            "from __future__ import print_function;" +
            "from distutils import sysconfig; import os; " +
            'print(os.path.join(*sysconfig.get_config_vars("LIBDIR", "LDLIBRARY")))',
        ],
        error_msg = "Problem getting python import library.",
    )

    return repository_ctx.path(result.stdout.splitlines()[0])

def _get_python_version(repository_ctx, python_bin):
    """Get Python import library"""
    result = _execute(
        repository_ctx,
        [
            python_bin,
            "-c",
            "from __future__ import print_function;" +
            "import sys;" +
            "print(sys.version_info[0]);" +
            "print(sys.version_info[1])",
        ],
        error_msg = "Problem getting python versiony.",
    )

    return [int(v) for v in result.stdout.splitlines()]

def _get_python_config_flags(repository_ctx, python_config_bin, flags):
    result = _execute(
        repository_ctx,
        [
            python_config_bin,
            flags,
        ],
        error_msg = "Problem getting python-config %s." % flags,
    ).stdout.splitlines()[0]
    return ",\n    ".join([
        '"%s"' % flag
        for flag in result.split(" ")
        if not flag.startswith("-I")
    ])

def _python_autoconf_impl(repository_ctx):
    """Implementation of the python_autoconf repository rule.

    Creates the repository containing files set up to build with Python.
    """
    python_bin = _get_bin(repository_ctx, repository_ctx.attr.interpreter)
    python_include = _get_python_include(repository_ctx, python_bin)
    python_import_lib = _get_python_import_lib_path(repository_ctx, python_bin)
    python_version = _get_python_version(repository_ctx, python_bin)
    if repository_ctx.attr.devel:
        python_config_bin = _get_bin(repository_ctx, repository_ctx.attr.interpreter + "-config")
        python_cflags = _get_python_config_flags(repository_ctx, python_config_bin, "--cflags")
        python_ldflags = _get_python_config_flags(repository_ctx, python_config_bin, "--ldflags")
        if python_version[0] > 2:
            python_extension_suffix = _get_python_config_flags(repository_ctx, python_config_bin, "--extension-suffix")
        else:
            python_extension_suffix = '".so"'
        repository_ctx.symlink(python_bin, "python")
        repository_ctx.symlink(python_include, "include")
        repository_ctx.symlink(python_import_lib, "lib/" + python_import_lib.basename)
        _tpl(repository_ctx, "BUILD")
        _tpl(repository_ctx, "defs.bzl", substitutions = {
            "%{CPYTHON}": repository_ctx.name,
            "%{CFLAGS}": python_cflags,
            "%{LDFLAGS}": python_ldflags,
            "%{EXTENSION_SUFFIX}": python_extension_suffix,
        })

python_configure = repository_rule(
    attrs = {
        "interpreter": attr.string(),
        "devel": attr.bool(default = False, doc = "Add support for compiling python extension"),
    },
    implementation = _python_autoconf_impl,
    configure = True,
    local = True,
)
