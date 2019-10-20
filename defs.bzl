"""Import pip requirements into Bazel."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

_PYTHON_BIN_PATH = "PIP_PYTHON_BIN_PATH"

def _get_python_bin(repository_ctx):
    """Gets the python bin path."""

    # if python bin is provided use that
    python_bin = repository_ctx.os.environ.get(_PYTHON_BIN_PATH)
    if python_bin != None:
        return python_bin

    python_bin_path = repository_ctx.which("python" + repository_ctx.attr.python_version)
    if python_bin_path != None:
        return str(python_bin_path)
    fail("Cannot find python%s in PATH, please make sure it is installed" % repository_ctx.attr.python_version)

def _pip_import_impl(repository_ctx):
    """Core implementation of pip_import."""
    repository_ctx.file("BUILD", "")
    repository_ctx.symlink(repository_ctx.attr.requirements, "requirements.txt")

    result = repository_ctx.execute([
        _get_python_bin(repository_ctx),
        repository_ctx.path(repository_ctx.attr._script),
        "--name",
        repository_ctx.attr.name,
        "--input",
        repository_ctx.path("requirements.txt"),
        "--output",
        repository_ctx.path("requirements.bzl"),
        "--python-version",
        repository_ctx.attr.python_version,
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
        "python_version": attr.string(
            mandatory = True,
            doc = "python-version for which fetch, install and find the " +
                  "dependencies of packages. It is passed to 'pip install'",
        ),
        "_script": attr.label(
            executable = True,
            default = Label("//tools:piptool.par"),
            allow_single_file = True,
            cfg = "host",
        ),
    },
    environ = [
        _PYTHON_BIN_PATH,
    ],
    implementation = _pip_import_impl,
)

def _whl_impl(repository_ctx):
    """Core implementation of whl_library."""

    args = [
        _get_python_bin(repository_ctx),
        repository_ctx.path(repository_ctx.attr._script),
        "--requirements",
        repository_ctx.attr.requirements_repo,
        "--directory",
        repository_ctx.path("."),
        "--constraint",
        repository_ctx.path(
            Label("%s//:requirements.txt" % repository_ctx.attr.requirements_repo),
        ),
        "--python-version",
        repository_ctx.attr.python_version,
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

    result = repository_ctx.execute(args)
    if result.return_code:
        fail("whl_library failed: %s (%s)" % (result.stdout, result.stderr))

whl_library = repository_rule(
    attrs = {
        "pkg": attr.string(),
        "requirements_repo": attr.string(),
        "extras": attr.string_list(),
        "python_version": attr.string(),
        "pip_args": attr.string_list(default = []),
        "_script": attr.label(
            executable = True,
            default = Label("//tools:whl.par"),
            cfg = "host",
        ),
    },
    environ = [
        _PYTHON_BIN_PATH,
    ],
    implementation = _whl_impl,
)

def py_pytest_test(name, **kwargs):
    """A macro that runs pytest tests by using a test runner
    :param name: rule name
    :param kwargs: are passed to py_test, with srcs and deps attrs modified
    """

    if "main" in kwargs:
        fail("if you need to specify main, use py_test directly")

    deps = kwargs.pop("deps", []) + ["@com_github_alish_rules_pip_lock//src:pytest_helper"]
    srcs = kwargs.pop("srcs", []) + ["@com_github_alish_rules_pip_lock//src:pytest_helper"]

    # failsafe, pytest won't work otw.
    for src in srcs:
        if name == src.split("/", maxsplit = 1)[0]:
            fail("rule name (%s) cannot be the same as the" +
                 "directory of the tests (%s)" % (name, src))

    native.py_test(
        name = name,
        srcs = srcs,
        main = "pytest_helper.py",
        deps = deps,
        **kwargs
    )

def repositories():
    if "rules_python" not in native.existing_rules():
        http_archive(
            name = "rules_python",
            sha256 = "9c11cd9e59e15c2ded113033d5ba43908b257ed23821809742627c36ccebdd8e",
            strip_prefix = "rules_python-120590e2f2b66e5590bf4dc8ebef9c5338984775",
            urls = ["https://github.com/bazelbuild/rules_python/archive/120590e2f2b66e5590bf4dc8ebef9c5338984775.zip"],
        )
    if "subpar" not in native.existing_rules():
        http_archive(
            name = "subpar",
            sha256 = "b80297a1b8d38027a86836dbadc22f55dc3ecad56728175381aa6330705ac10f",
            strip_prefix = "subpar-2.0.0",
            urls = ["https://github.com/google/subpar/archive/2.0.0.tar.gz"],
        )
