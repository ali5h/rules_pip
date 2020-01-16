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

def _get_python_bin(repository_ctx):
    """Gets the python bin path."""
    python_bin_path = repository_ctx.which(repository_ctx.attr.interpreter)
    if python_bin_path != None:
        return str(python_bin_path)
    _fail("Cannot find python in PATH, please make sure " +
          "python is installed and add its directory in PATH, or --define " +
          "%s='/something/else'.\nPATH=%s" % (
              repository_ctx.attr.interpreter,
              repository_ctx.os.environ.get("PATH", ""),
          ))

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
        error_details = ("Is the Python binary path set up right? " +
                         "(See ./configure or " + python_bin + ".) " +
                         "Is distutils installed?"),
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
        error_details = ("Is the Python binary path set up right? " +
                         "(See ./configure or " + python_bin + ".) "),
    )

    return repository_ctx.path(result.stdout.splitlines()[0])

def _create_local_python_repository(repository_ctx):
    """Creates the repository containing files set up to build with Python."""
    python_bin = _get_python_bin(repository_ctx)
    python_include = _get_python_include(repository_ctx, python_bin)
    python_import_lib = _get_python_import_lib_path(repository_ctx, python_bin)
    repository_ctx.symlink(python_bin, "python")
    repository_ctx.symlink(python_include, "include")
    repository_ctx.symlink(python_import_lib, "lib/" + python_import_lib.basename)
    _tpl(repository_ctx, "BUILD")

def _python_autoconf_impl(repository_ctx):
    """Implementation of the python_autoconf repository rule."""
    _create_local_python_repository(repository_ctx)

python_configure = repository_rule(
    attrs = {
        "interpreter": attr.string(),
    },
    implementation = _python_autoconf_impl,
    configure = True,
    local = True,
)
