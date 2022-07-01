"""Import pip requirements into Bazel."""

pip_vendor_label = Label("@com_github_ali5h_rules_pip//:third_party/py/BUILD")

def _execute(repository_ctx, arguments, quiet = False):
    pip_vendor = str(repository_ctx.path(pip_vendor_label).dirname)
    return repository_ctx.execute(arguments, environment = {
        "PYTHONPATH": pip_vendor,
    }, timeout = repository_ctx.attr.timeout, quiet = quiet)

def _pip_import_impl(repository_ctx):
    """Core implementation of pip_import."""

    python_interpreter = repository_ctx.attr.python_interpreter
    if repository_ctx.attr.python_runtime:
        python_interpreter = repository_ctx.path(repository_ctx.attr.python_runtime)

    repository_ctx.file("BUILD", "")
    reqs = repository_ctx.read(repository_ctx.attr.requirements)

    # make a copy for compile
    repository_ctx.file("requirements.txt", content = reqs, executable = False)
    if repository_ctx.attr.compile:
        result = _execute(repository_ctx, [
            python_interpreter,
            repository_ctx.path(repository_ctx.attr._compiler),
            "--quiet",
            "--allow-unsafe",
            "--no-emit-trusted-host",
            "--build-isolation",
            "--no-emit-find-links",
            "--no-header",
            "--no-index",
            "--no-annotate",
            repository_ctx.path("requirements.txt"),
        ], quiet = repository_ctx.attr.quiet)
        if result.return_code:
            fail("pip_compile failed: %s (%s)" % (result.stdout, result.stderr))

    args = [
        python_interpreter,
        repository_ctx.path(repository_ctx.attr._script),
        "--name",
        repository_ctx.attr.name,
        "--input",
        repository_ctx.path("requirements.txt"),
        "--output",
        repository_ctx.path("requirements.bzl"),
        "--timeout",
        str(repository_ctx.attr.timeout),
        "--repo-prefix",
        str(repository_ctx.attr.repo_prefix),
        "--quiet",
        str(repository_ctx.attr.quiet),
    ]

    for label, pipdep in repository_ctx.attr.overrides.items():
        args += ["--override=%s=%s" % (label, pipdep)]
    if repository_ctx.attr.cc_import:
        args += ["--cc_import"]

    result = _execute(repository_ctx, args, quiet = repository_ctx.attr.quiet)
    if result.return_code:
        fail("pip_import failed: %s (%s)" % (result.stdout, result.stderr))

pip_import = repository_rule(
    attrs = {
        "requirements": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "requirement.txt file generatd by pip-compile",
        ),
        "python_interpreter": attr.string(default = "python", doc = """
The command to run the Python interpreter used to invoke pip and unpack the
wheels.
"""),
        "python_runtime": attr.label(doc = """
The label to the Python run-time interpreted used to invoke pip and unpack the wheels.
If the label is specified it will overwrite the python_interpreter attribute.
"""),
        "repo_prefix": attr.string(default = "pypi", doc = """
The prefix for the bazel repository name.
"""),
        "compile": attr.bool(
            default = False,
        ),
        "overrides": attr.label_keyed_string_dict(doc = """
Specify to replace certain pip dependencies with bazel dependencies.

pip_import(
    name = "pipdeps",
    ...
    overrides = {
        "@com_google_protobuf//:protobuf_python": "protobuf",
    },
)

This replaces "protobuf" with the bazel version even for indirect dependencies on it.
"""),
        "timeout": attr.int(default = 1200, doc = "Timeout for pip actions"),
        "cc_import": attr.bool(doc = "Enable cc_import() for shared libraries."),
        "_script": attr.label(
            executable = True,
            default = Label("@com_github_ali5h_rules_pip//src:piptool.py"),
            allow_single_file = True,
            cfg = "host",
        ),
        "_compiler": attr.label(
            executable = True,
            default = Label("@com_github_ali5h_rules_pip//src:compile.py"),
            allow_single_file = True,
            cfg = "host",
        ),
        "quiet": attr.bool(
            default = True,
            doc = "If stdout and stderr should be printed to the terminal.",
        ),
    },
    implementation = _pip_import_impl,
)

def _whl_impl(repository_ctx):
    """Core implementation of whl_library."""

    python_interpreter = repository_ctx.attr.python_interpreter
    if repository_ctx.attr.python_runtime:
        python_interpreter = repository_ctx.path(repository_ctx.attr.python_runtime)

    pip_args = repository_ctx.attr.pip_args
    if "--timeout" not in repository_ctx.attr.pip_args:
        pip_args = repository_ctx.attr.pip_args + ["--timeout", str(repository_ctx.attr.timeout)]

    args = [
        python_interpreter,
        repository_ctx.path(repository_ctx.attr._script),
        "--requirements",
        repository_ctx.attr.requirements_repo,
        "--directory",
        repository_ctx.path("."),
        "--constraint",
        repository_ctx.path(
            Label("%s//:requirements.txt" % repository_ctx.attr.requirements_repo),
        ),
        "--package",
        repository_ctx.attr.pkg,
    ]
    if repository_ctx.attr.extras:
        args += [
            "--extras=%s" % extra
            for extra in repository_ctx.attr.extras
        ]
    for label, pipdep in repository_ctx.attr.overrides.items():
        args += ["--override=%s=%s" % (label, pipdep)]
    if repository_ctx.attr.cc_import:
        args += ["--cc_import"]

    args += pip_args

    result = _execute(repository_ctx, args, quiet = repository_ctx.attr.quiet)
    if result.return_code:
        fail("whl_library failed: %s (%s)" % (result.stdout, result.stderr))

whl_library = repository_rule(
    attrs = {
        "pkg": attr.string(),
        "requirements_repo": attr.string(),
        "extras": attr.string_list(),
        "python_interpreter": attr.string(default = "python", doc = """
The command to run the Python interpreter used to invoke pip and unpack the
wheels.
"""),
        "python_runtime": attr.label(doc = """
The label to the Python run-time interpreted used to invoke pip and unpack the wheels.
If the label is specified it will overwrite the python_interpreter attribute.
"""),
        "pip_args": attr.string_list(default = []),
        "timeout": attr.int(default = 1200, doc = "Timeout for pip actions"),
        "overrides": attr.label_keyed_string_dict(),
        "cc_import": attr.bool(),
        "_script": attr.label(
            executable = True,
            default = Label("@com_github_ali5h_rules_pip//src:whl.py"),
            cfg = "host",
        ),
        "quiet": attr.bool(
            default = True,
            doc = "If stdout and stderr should be printed to the terminal.",
        ),
    },
    implementation = _whl_impl,
)

def py_pytest_test(
        name,
        # This argument exists for back-compatibility with earlier versions
        pytest_args = [
            "--ignore=external",
            ".",
            "-p",
            "no:cacheprovider",
        ],
        **kwargs):
    """A macro that runs pytest tests by using a test runner.

    Args:
        name: A unique name for this rule.
        pytest_args: a list of arguments passed to pytest
        **kwargs: are passed to py_test, with srcs and deps attrs modified
    """

    if "main" in kwargs:
        fail("if you need to specify main, use py_test directly")

    deps = kwargs.pop("deps", []) + ["@com_github_ali5h_rules_pip//src:pytest_helper"]
    srcs = kwargs.pop("srcs", []) + ["@com_github_ali5h_rules_pip//src:pytest_helper"]
    args = kwargs.pop("args", []) + pytest_args

    # failsafe, pytest won't work otw.
    for src in srcs:
        if name == src.split("/", 1)[0]:
            fail("rule name (%s) cannot be the same as the" +
                 "directory of the tests (%s)" % (name, src))

    native.py_test(
        name = name,
        srcs = srcs,
        main = "pytest_helper.py",
        deps = deps,
        args = args,
        **kwargs
    )
