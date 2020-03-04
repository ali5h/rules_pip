#define PY_SSIZE_T_CLEAN
#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION
#include "Python.h"
#include "numpy/arrayobject.h"


static struct PyModuleDef moduledef = {
     PyModuleDef_HEAD_INIT, "_test",
     NULL,
     -1,
};


PyMODINIT_FUNC PyInit__test(void) {
  import_array();
  return PyModule_Create(&moduledef);
}
