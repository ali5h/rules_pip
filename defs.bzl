"""Import pip requirements into Bazel."""

pip_vendor_label = Label("@com_github_ali5h_rules_pip//:third_party/py/easy_install.py")

def _execute(repository_ctx, arguments):
    pip_vendor = str(repository_ctx.path(repository_ctx.attr._vendor).dirname)
    return repository_ctx.execute(arguments, environment = {
        "PYTHONPATH": pip_vendor,
    })

def _pip_import_impl(repository_ctx):
    """Core implementation of pip_import."""
    repository_ctx.file("BUILD", "")
    repository_ctx.symlink(repository_ctx.attr.requirements, "requirements.in")
    reqs = repository_ctx.read("requirements.in")

    # make a copy for compile
    repository_ctx.file("requirements.txt", content = reqs, executable = False)
    if repository_ctx.attr.compile:
        result = _execute(repository_ctx, [
            repository_ctx.attr.python_interpreter,
            repository_ctx.path(repository_ctx.attr._compiler),
            "--allow-unsafe",
            "--no-emit-trusted-host",
            "--build-isolation",
            "--no-emit-find-links",
            "--no-header",
            "--no-index",
            "--output-file",
            repository_ctx.path("requirements.txt"),
            repository_ctx.path("requirements.in"),
        ])
        if result.return_code:
            fail("pip_compile failed: %s (%s)" % (result.stdout, result.stderr))

    result = _execute(repository_ctx, [
        repository_ctx.attr.python_interpreter,
        repository_ctx.path(repository_ctx.attr._script),
        "--name",
        repository_ctx.attr.name,
        "--input",
        repository_ctx.path("requirements.txt"),
        "--output",
        repository_ctx.path("requirements.bzl"),
    ])
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
        "compile": attr.bool(
            default = True,
        ),
        "_script": attr.label(
            executable = True,
            default = Label("//tools:piptool.par"),
            cfg = "host",
        ),
        "_compiler": attr.label(
            executable = True,
            default = Label("//tools:compile.par"),
            cfg = "host",
        ),
        "_vendor": attr.label(
            executable = True,
            default = pip_vendor_label,
            allow_single_file = True,
            cfg = "host",
        ),
    },
    implementation = _pip_import_impl,
)

def _whl_impl(repository_ctx):
    """Core implementation of whl_library."""

    args = [
        repository_ctx.attr.python_interpreter,
        repository_ctx.path(repository_ctx.attr._script),
        "--requirements",
        repository_ctx.attr.requirements_repo,
        "--directory",
        repository_ctx.path("."),
        "--constraint",
        repository_ctx.path(
            Label("%s//:requirements.txt" % repository_ctx.attr.requirements_repo),
        ),
        repository_ctx.attr.pkg,
    ] + [
        "--pip-arg=%s" % pip_arg
        for pip_arg in repository_ctx.attr.pip_args
    ]
    if repository_ctx.attr.extras:
        args += [
            "--extras=%s" % extra
            for extra in repository_ctx.attr.extras
        ]

    result = _execute(repository_ctx, args)
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
        "pip_args": attr.string_list(default = []),
        "_script": attr.label(
            executable = True,
            default = Label("//tools:whl.par"),
            cfg = "host",
        ),
        "_vendor": attr.label(
            executable = True,
            default = pip_vendor_label,
            allow_single_file = True,
            cfg = "host",
        ),
    },
    implementation = _whl_impl,
)

def py_pytest_test(name, **kwargs):
    """A macro that runs pytest tests by using a test runner
    :param name: rule name
    :param kwargs: are passed to py_test, with srcs and deps attrs modified
    """

    if "main" in kwargs:
        fail("if you need to specify main, use py_test directly")

    deps = kwargs.pop("deps", []) + ["@com_github_ali5h_rules_pip//src:pytest_helper"]
    srcs = kwargs.pop("srcs", []) + ["@com_github_ali5h_rules_pip//src:pytest_helper"]

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
        **kwargs
    )
