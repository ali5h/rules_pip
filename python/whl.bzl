"""Import .whl files into Bazel."""

def _whl_impl(repository_ctx):
    """Core implementation of whl_library."""

    args = [
        "python",
        repository_ctx.path(repository_ctx.attr._script),
        "--requirements",
        repository_ctx.attr.requirements_repo,
        "--directory",
        repository_ctx.path("."),
        "--constraint",
        repository_ctx.path(
            Label("%s//:requirements.txt" % repository_ctx.attr.requirements_repo)
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
            default = Label("//tools:whl.zip"),
            cfg = "host",
        ),
    },
    implementation = _whl_impl,
)
