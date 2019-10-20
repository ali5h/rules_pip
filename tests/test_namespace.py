def test_import():
    # just try to import some packages that use namespace
    import google.cloud.language
    import testing.postgresql
    import testing.mysqld
