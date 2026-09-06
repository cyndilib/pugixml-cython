from pathlib import Path

from conftest import XmlTestCase

from pugixml_cython import Document


def test_get_by_node_position(xml_test_case: XmlTestCase) -> None:
    """Test that nodes can be retrieved by their node position
    """
    doc = Document()
    if isinstance(xml_test_case.xml, Path):
        xml_string = xml_test_case.xml.read_text()
    else:
        xml_string = xml_test_case.xml

    doc.load_string(xml_string)
    for expected in xml_test_case.expected.walk():
        if expected.node_position is None:
            continue
        node = doc.get_node_by_position(expected.node_position)
        assert node is not None
        assert node.node_position == expected.node_position
        expected.check(node, recurse=False)
