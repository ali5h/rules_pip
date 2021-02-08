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

def _get_python_include(repository_ctx):
    """Gets the python include path."""
    result = _execute(
        repository_ctx,
        [
            repository_ctx.attr.interpreter,
            "-c",
            "import sysconfig;print(sysconfig.get_path('include'))",
        ],
        error_msg = "Problem getting python include path.",
    )
    return repository_ctx.path(result.stdout.splitlines()[0])

def _get_python_lib_path(repository_ctx):
    """Get python cflags"""
    result = _execute(
        repository_ctx,
        [
            repository_ctx.attr.interpreter,
            "-c",
            "import sysconfig;print(sysconfig.get_config_var('LIBPL'))",
        ],
        error_msg = "Problem getting lib path.",
    )
    return repository_ctx.path(result.stdout.splitlines()[0])

def _get_python_config_cflags(repository_ctx):
    """Get python cflags"""
    result = _execute(
        repository_ctx,
        [
            repository_ctx.attr.interpreter,
            "-c",
            """
import sysconfig
for flag in sysconfig.get_config_var('CFLAGS').split():
  print(flag)
""",
        ],
        error_msg = "Problem getting cflags.",
    )
    return [
        flag
        for flag in result.stdout.splitlines()
        if flag != "-Wstrict-prototypes"
    ]

def _get_python_config_ldflags(repository_ctx):
    """Get python ldflags"""
    result = _execute(
        repository_ctx,
        [
            repository_ctx.attr.interpreter,
            "-c",
            """
import sysconfig
getvar = sysconfig.get_config_var
libs = ['-L' + getvar('LIBPL')]
libpython = getvar('LIBPYTHON')
if libpython:
    libs.append(libpython)
libs.extend(getvar('LIBS').split() + getvar('SYSLIBS').split())
for lib in libs:
  print(lib)
""",
        ],
        error_msg = "Problem getting ldflags.",
    )
    return result.stdout.splitlines()

def _get_python_config_ext(repository_ctx):
    """Get python extension suffix."""
    result = _execute(
        repository_ctx,
        [
            repository_ctx.attr.interpreter,
            "-c",
            "import sysconfig;print(sysconfig.get_config_var('EXT_SUFFIX') or '.so')",
        ],
        error_msg = "Problem getting extension suffix.",
    )
    return result.stdout.splitlines()[0]

def _python_autoconf_impl(repository_ctx):
    """Implementation of the python_autoconf repository rule.

    Creates the repository containing files set up to build with Python.
    """
    if repository_ctx.attr.devel:
        python_include = _get_python_include(repository_ctx)
        python_cflags = _get_python_config_cflags(repository_ctx)
        python_ldflags = _get_python_config_ldflags(repository_ctx)
        python_extension_suffix = _get_python_config_ext(repository_ctx)
        repository_ctx.symlink(python_include, "include")
        _tpl(repository_ctx, "BUILD")
        _tpl(repository_ctx, "defs.bzl", substitutions = {
            "%{CPYTHON}": repository_ctx.name,
            "%{CFLAGS}": ",\n    ".join(['"%s"' % flag for flag in python_cflags]),
            "%{LDFLAGS}": ",\n    ".join(['"%s"' % flag for flag in python_ldflags]),
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
