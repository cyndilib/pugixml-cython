import subprocess
from pathlib import Path

import pytest

from pugixml_cython import get_include_dirs

CYTHON_SOURCE = """\
# cython: language_level=3
# distutils: include_dirs=INCLUDE_DIRS

from argparse import ArgumentParser
from pathlib import Path

from libc.stddef cimport size_t
from pugixml_cython cimport Document, Element, NodeType

cdef Document doc = Document()


cdef load_xml_file(file_path: Path):
    cdef str content_str = file_path.read_text()
    cdef bytes content_bytes = content_str.encode('utf-8')
    doc._load_string(content_bytes)
    return doc._get_root()


def main(xml_file: Path):
    root = load_xml_file(xml_file)
    return root

"""


def test_cy_cross_compile(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    """Test to ensure that other Cython code can be compiled against pugixml_cython
    """

    # Set the proper `include_dirs` in the Cython source code
    include_dirs = ", ".join([str(p) for p in get_include_dirs()])
    cy_source = CYTHON_SOURCE.replace("INCLUDE_DIRS", str(include_dirs))

    # Write the Cython source and a test xml file to the temporary path
    cy_file = tmp_path / "test_cy.pyx"
    cy_file.write_text(cy_source)
    xml_file = tmp_path / "test.xml"
    xml_file.write_text('<root value="123"></root>')

    # Cythonize and compile the Cython source code
    subprocess.run(
        ["cythonize", "-i", str(cy_file)],
        check=True,
    )

    # Import and test
    monkeypatch.syspath_prepend(str(tmp_path))
    import test_cy # type: ignore  # NOQA: I001

    root = test_cy.main(xml_file)
    assert root.name == "root"
    assert root.attributes["value"] == "123"
