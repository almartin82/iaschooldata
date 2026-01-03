"""
Tests for pyiaschooldata Python wrapper.

Minimal smoke tests - the actual data logic is tested by R testthat.
These just verify the Python wrapper imports and exposes expected functions.
"""

import pytest


def test_import_package():
    """Package imports successfully."""
    import pyiaschooldata
    assert pyiaschooldata is not None


def test_has_fetch_enr():
    """fetch_enr function is available."""
    import pyiaschooldata
    assert hasattr(pyiaschooldata, 'fetch_enr')
    assert callable(pyiaschooldata.fetch_enr)


def test_has_get_available_years():
    """get_available_years function is available."""
    import pyiaschooldata
    assert hasattr(pyiaschooldata, 'get_available_years')
    assert callable(pyiaschooldata.get_available_years)


def test_has_version():
    """Package has a version string."""
    import pyiaschooldata
    assert hasattr(pyiaschooldata, '__version__')
    assert isinstance(pyiaschooldata.__version__, str)
