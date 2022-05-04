def test_import():
    # just try to import some packages that use namespace
    import google.cloud.language
    import azure.storage.blob
    import dateutil
    import prometheus_client


def test_xgboost():
    import xgboost.training


def test_numpy():
    import numpy
    import tests._test


def test_pytz():
    import pytz

    # This attribute doesn't exist upstream, so this test would normally fail.
    # However, we overrode pytz with our own (plus a patch), so this attribute will exist.
    # If this test fails, it's likely because pytz is not being overridden.
    assert pytz.NEW_ATTR
