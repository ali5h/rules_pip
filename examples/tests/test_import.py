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
    assert pytz.NEW_ATTR
