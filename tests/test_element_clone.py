from pathlib import Path

from conftest import XmlTestCase

from pugixml_cython import Document


def test_element_clone(xml_test_case: XmlTestCase) -> None:
    doc = Document()
    if isinstance(xml_test_case.xml, Path):
        xml_string = xml_test_case.xml.read_text()
    else:
        xml_string = xml_test_case.xml

    doc.load_string(xml_string)
    root_element = doc.get_root()
    assert root_element is not None
    xml_test_case.expected.check(root_element)
    cloned_element = root_element.clone(doc)
    assert cloned_element is not None
    assert cloned_element is not root_element
    xml_test_case.expected.check(cloned_element)

    # Clear the document and delete the original root element to ensure the
    # cloned element is independent
    doc.clear()
    del root_element
    xml_test_case.expected.check(cloned_element)


def test_element_clone_non_root(xml_test_case: XmlTestCase) -> None:
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

        cloned_element = node.clone(doc)
        assert cloned_element is not None
        assert cloned_element is not node

        # The node position will not match for the cloned element since it's
        # not part of the same tree.  We can still check all other attributes and structure.
        expected.check(cloned_element, match_position=False)
