# Bazel pip rules

## Overview

This repository provides support for installing `pip` packages. Usage
is similar to `rules_python`.

## Main features

- Fetch pip packages incrementally. Fetch happens only if needed by a target.

- Support for namespace packages

- Reproducible wheel builds.

- Support for passing arguments to `pip_install`. You can optionally
  pass the same arguments that `pip install` accepts to
  `pip_install`. For example, if you have wheels for all the packages
  you can have `pip_install(["--only-binary", ":all"])`.

- Support for python version. The assumption is that each python
  version has its own requirements file and the python binary of that
  version exists in the global environment.

__NOTE__: For full hermetic builds always use a requirements files
  that is produced by `pip-compile`. In that case, you can disable
  internal call to `pip-compile` by passing `compile = False` to
  `pip_import` rule. Also pre-build the wheels in advance.


## Setup

Add the following to your `WORKSPACE` file:

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "http_archive")

http_archive(
    name = "com_github_ali5h_rules_pip",
    strip_prefix = "rules_pip-<revision>",
    sha256 = "<revision_hash>",
    urls = ["https://github.com/ali5h/rules_pip/archive/<revision>.tar.gz"],
)

load("@com_github_ali5h_rules_pip//:defs.bzl", "pip_import")

pip_import(
   name = "pip_deps",
   requirements = "//path/to:requirements.txt",

   # default value is "python"
   # python_interpreter="python3",

   # or specify a python runtime label
   # python_runtime="@python3_x86_64//:bin/python3",

   # set compile to false only if requirements files is already compiled
   # compile = False
)

load("@pip_deps//:requirements.bzl", "pip_install")
pip_install([<optional pip install args])
```
