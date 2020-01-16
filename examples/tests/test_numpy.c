#include "Python.h"                 // Python API
#include "numpy/arrayobject.h"


static struct PyModuleDef moduledef = {
     PyModuleDef_HEAD_INIT, "_test",       /* m_name */
     NULL,                                 /* m_doc */
     -1,                                   /* m_size */
     NULL,                                 /* m_methods */
     NULL,                                 /* m_reload */
     NULL,                                 /* m_traverse */
     NULL,                                 /* m_clear */
     NULL,                                 /* m_free */
};


PyMODINIT_FUNC PyInit__test(void) {
  import_array();
  PyObject *m;
  m = PyModule_Create(&moduledef);
  return m;
}
