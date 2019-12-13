def test_import():
    # just try to import some packages that use namespace
    import google.cloud.language
    import testing.postgresql
    import testing.mysqld
    import tensorflow as tf
    import azure.common
    import azure.storage.blob
