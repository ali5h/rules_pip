"""Import pip requirements into Bazel."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def _pip_import_impl(repository_ctx):
    """Core implementation of pip_import."""
    repository_ctx.file("BUILD", "")
    repository_ctx.symlink(repository_ctx.attr.requirements, "requirements.txt")

    # To see the output, pass: quiet=False
    result = repository_ctx.execute([
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
        ),
        "_script": attr.label(
            executable = True,
            default = Label("//tools:piptool.par"),
            allow_single_file = True,
            cfg = "host",
        ),
    },
    implementation = _pip_import_impl,
)

def _whl_impl(repository_ctx):
    """Core implementation of whl_library."""

    args = [
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
        "_script": attr.label(
            executable = True,
            default = Label("//tools:whl.par"),
            cfg = "host",
        ),
    },
    implementation = _whl_impl,
)

def repositories():
    if "rules_python" not in native.existing_rules():
        http_archive(
            name = "rules_python",
            sha256 = "9c11cd9e59e15c2ded113033d5ba43908b257ed23821809742627c36ccebdd8e",
            strip_prefix = "rules_python-120590e2f2b66e5590bf4dc8ebef9c5338984775",
            urls = ["https://github.com/bazelbuild/rules_python/archive/120590e2f2b66e5590bf4dc8ebef9c5338984775.zip"],
        )
        http_archive(
            name = "subpar",
            sha256 = "b80297a1b8d38027a86836dbadc22f55dc3ecad56728175381aa6330705ac10f",
            strip_prefix = "subpar-2.0.0",
            urls = ["https://github.com/google/subpar/archive/2.0.0.tar.gz"],
        )
