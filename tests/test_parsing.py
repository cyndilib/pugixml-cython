from pathlib import Path

from conftest import XmlResult, XmlTestCase

from pugixml_cython import Document, NodeType


def test_parsing(xml_test_case: XmlTestCase) -> None:
    """Test parsing of XML documents using the Document class.
    """
    doc = Document()
    if isinstance(xml_test_case.xml, Path):
        xml_string = xml_test_case.xml.read_text()
    else:
        xml_string = xml_test_case.xml

    assert not doc.has_document
    doc.load_string(xml_string)
    assert doc.has_document
    root = doc.get_root()
    assert doc.has_root
    assert root is not None

    # check_element(root, xml_test_case.expected)
    xml_test_case.expected.check(root)


def test_parse_filter_cdata() -> None:
    """Test parsing of XML documents with CDATA nodes filtered out.
    """
    xml_string = """<root><![CDATA[Some cdata content]]><element>Text</element></root>"""
    doc = Document()

    # First check to ensure the document loads all nodes
    doc.load_string(xml_string)
    root = doc.get_root()
    assert root is not None
    assert len(root) == 2

    # Now check the document with CDATA nodes excluded
    expected = XmlResult(
        tag="root",
        text=None,
        attrib={},
        children=[
            XmlResult(
                tag="element",
                text="Text",
                attrib={},
                children=[]
            )
        ]
    )
    doc.add_node_type_exclusion(NodeType.NODE_CDATA)
    doc.load_string(xml_string)
    root = doc.get_root()
    assert root is not None
    assert len(root) == 1
    expected.check(root)



# TODO: comment nodes don't appear to be parsed correctly
# def test_parse_filter_comment() -> None:
#     xml_string = """<root><!-- This is a comment --><element>Text</element></root>"""
#     doc = Document()

#     # First check to ensure the document loads all nodes including comments
#     doc.load_string(xml_string)
#     root = doc.get_root()
#     assert root is not None
#     assert len(root) == 2

#     # Now check the document with comment nodes excluded
#     doc.add_node_type_exclusion(NodeType.NODE_COMMENT)
#     doc.load_string(xml_string)
#     root = doc.get_root()
#     assert root is not None
#     assert len(root) == 1
#     assert root.text is None
#     assert root.name == "root"
#     assert root[0].name == "element"
#     assert root[0].text == "Text"


# TODO: Processing instruction nodes don't appear to be parsed correctly
# def test_parse_filter_pi() -> None:
#     xml_string = """<root><?pi data?><element>Text</element></root>"""
#     doc = Document()

#     # First check to ensure the document loads all nodes including processing instructions
#     doc.load_string(xml_string)
#     root = doc.get_root()
#     assert root is not None
#     assert root[0].type == NodeType.NODE_PI
#     assert len(root) == 2

#     # Now check the document with processing instruction nodes excluded
#     doc.add_node_type_exclusion(NodeType.NODE_PI)
#     doc.load_string(xml_string)
#     root = doc.get_root()
#     assert root is not None
#     assert len(root) == 1
#     assert root.text is None
#     assert root.name == "root"
#     assert root[0].name == "element"
#     assert root[0].text == "Text"


def test_parse_filter_element() -> None:
    """Test parsing of XML documents with element nodes filtered out.
    """
    xml_string = """<root><element>Text</element><element>More text</element></root>"""
    doc = Document()
    expected = XmlResult(
        tag="root",
        text=None,
        attrib={},
        children=[
            XmlResult(
                tag="element",
                text="Text",
                attrib={},
                children=[]
            ),
            XmlResult(
                tag="element",
                text="More text",
                attrib={},
                children=[]
            )
        ]
    )

    # First check to ensure the document loads all element nodes
    doc.load_string(xml_string)
    root = doc.get_root()
    assert root is not None
    assert len(root) == 2
    expected.check(root)

    # Now check the document with element nodes excluded
    expected = XmlResult(
        tag="root",
        text=None,
        attrib={},
        children=[]
    )
    doc.add_node_type_exclusion(NodeType.NODE_ELEMENT)
    doc.load_string(xml_string)
    root = doc.get_root()
    assert root is not None
    assert len(root) == 0
    # assert root.text is None
    # assert root.name == "root"
    expected.check(root)


def test_doc_clear() -> None:
    """Test clearing and reloading of XML documents using the Document class.
    """
    xml_string = """<root><element>Text</element></root>"""
    doc = Document()
    doc.load_string(xml_string)
    root = doc.get_root()
    assert root is not None
    assert len(root) == 1
    doc.clear()
    assert not doc.has_document
    assert not doc.has_root

    # Reload the document after clearing
    doc.load_string(xml_string)
    root = doc.get_root()
    assert root is not None
    assert len(root) == 1
    assert root[0].name == "element"
    assert root[0].text == "Text"
