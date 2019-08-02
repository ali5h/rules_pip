#!/bin/bash -eu

usage() {
  echo "Usage: $0" 1>&2
  exit 1
}

if [ "$#" -eq 0 ] ; then
    bazel test //...
    bazel build //rules_pip_lock:piptool.par //rules_pip_lock:whl.par
    install $(bazel info bazel-bin)/rules_pip_lock/{piptool,whl}.par tools/
else
  usage
fi
