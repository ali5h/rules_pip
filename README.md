# Bazel pip rules

These rules fetches pip packages using requirements file generated with `pip-compile`.

## Overview

This repository provides support for installing dependencies typically
managed via `pip`. Usage is similar to `rules_python`. Main difference
is that `requirement.txt` must have been produced by
`pip-compile`. This means that dependecies of all the pip packages are
already resolved and bazel can fetch them in parallel.

There is also support for python version. The assumption is each
python version has its own requirement files. python binary of that version should exist in the global environe


## Setup

Add the following to your `WORKSPACE` file:

```python
load("@bazel_tools//tools/build_defs/repo:git.bzl", "http_archive")

http_archive(
    name = "com_github_alish_rules_pip_lock",
    strip_prefix = "rules_pip_lock-0.2.0",
    urls = ["https://github.com/ali5h/rules_pip_lock/archive/0.2.0.tar.gz"],
)

load("@com_github_alish_rules_pip_lock//:defs.bzl", "pip_import", "repositories")

repositories()

pip_import(
   name = "my_deps",
   requirements = "//path/to:requirements.txt",
   python_version="3.6",
)

load("@my_deps//:requirements.bzl", "pip_install")
pip_install(["--only-binary", ":all"])
```

## Updating `tools/`

All of the content (except `BUILD`) under `tools/` is generated.  To update the
tools simply run this in the root of the repository:
```shell
./update_tools
```
