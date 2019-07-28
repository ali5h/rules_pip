#!/bin/bash -eu

usage() {
  echo "Usage: $0" 1>&2
  exit 1
}

if [ "$#" -eq 0 ] ; then
    bazel build --build_python_zip //rules_pip_lock:piptool //rules_pip_lock:whl
    install $(bazel info bazel-bin --python_version=PY2)/rules_pip_lock/{piptool,whl}.zip tools/
else
  usage
fi
