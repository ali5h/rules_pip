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

### requirements file
For full hermetic builds always use a requirements files
that is produced by `pip-compile`. Also pre-build the wheels in advance.
You can run `pip-compile` as:

  ```
  $ pip-compile --allow-unsafe requirements.in
  ```

`--allow-unsafe` is important. For example some packages need
`setuptools` and we need it to be in requirements file.

Otherwise, you can set `compile=True` in `pip_import` rule and the
rule will try to compile the requirements file. But this process is
fragile.

## Setup

Add the following to your `WORKSPACE` file:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

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

   # set compile to true only if requirements files is not already compiled
   # compile = True
)

load("@pip_deps//:requirements.bzl", "pip_install")
pip_install([<optional pip install args])
```

## Target dependencies

To use pip packages you can

* add dependencies via `requirement` macro as

```python
load("@pip_deps//:requirements.bzl", "requirement")

py_binary(
    name = "main",
    srcs = ["main.py"],
    deps = [
        requirement("pip-module")
    ]
)
```

* use package aliases as

```python
py_binary(
    name = "main",
    srcs = ["main.py"],
    deps = [
        "@pip_deps//:pip-module"
    ]
)
```
