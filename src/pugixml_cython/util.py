import importlib.resources
from pathlib import Path


def _get_resource_path(package: str, resource: str) -> Path:
    p = importlib.resources.files(package) / resource
    assert isinstance(p, Path)
    return p


def get_include_dirs() -> list[Path]:
    """Get the include directories for the pugixml Cython extension.

    This function is intended to be used when integrating this library
    into other extension modules (e.g., the `include_dirs` argument of
    `setuptools.Extension`).
    """
    return [
        _get_resource_path("pugixml_cython.extern", "pugixml/src")
    ]
