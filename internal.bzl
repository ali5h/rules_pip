
def _expose_cc_import_as_runfiles_impl(ctx):
    cc_info = ctx.attr.src[CcInfo]

    runfiles = []
    
    for linker_input in cc_info.linking_context.linker_inputs.to_list():
        for library in linker_input.libraries:
            if library.dynamic_library:
                runfiles.append(library.dynamic_library)
            if library.resolved_symlink_dynamic_library:
                runfiles.append(library.resolved_symlink_dynamic_library)

    # print(runfiles)
    return [
        cc_info,
        DefaultInfo(runfiles = ctx.runfiles(files = runfiles)),
    ]


expose_cc_import_as_runfiles = rule(
    attrs = {
        "src": attr.label(mandatory = True, providers = [CcInfo]),
    },
    implementation = _expose_cc_import_as_runfiles_impl,
)
