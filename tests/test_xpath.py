import pytest

from pugixml_cython import Document

# Sample XML document to test xpath queries against
XML_DOCUMENT = """\
<root>
    <body class="main">
        <head torso="upper" class="body-part">
            <ears class="body-part-group">
                <ear class="body-part" side="left"/>
                <ear class="body-part" side="right"/>
            </ears>
        </head>
        <legs class="body-part-group" torso="lower">
            <leg class="body-part" side="left"/>
            <leg class="body-part" side="right"/>
        </legs>
    </body>
</root>
"""


def test_xpath_single_queries() -> None:
    doc = Document()
    doc.load_string(XML_DOCUMENT)
    root = doc.get_root()
    assert root is not None

    # Test single element queries
    elem = doc.xpath_find(".//body")
    assert elem is not None and elem.name == "body"
    elem = doc.xpath_find(".//body/head")
    assert elem is not None and elem.name == "head"
    elem = doc.xpath_find(".//body/head/ears/ear[@side='left']")
    assert elem is not None and elem.name == "ear"
    elem = doc.xpath_find(".//body/legs/leg[@side='right']")
    assert elem is not None and elem.name == "leg"

    # Test grandchildren queries
    elem = doc.xpath_find(".//ear[@side='left']")
    assert elem is not None and elem.name == "ear"
    elem = doc.xpath_find(".//leg[@side='right']")
    assert elem is not None and elem.name == "leg"

    # Test parent select `..` queries
    elem = doc.xpath_find(".//body/legs/leg[@side='left']/..")
    assert elem is not None and elem.name == "legs"

    # Find node with `torso="lower"` that has a child `leg` with `side="left"`
    elem = doc.xpath_find(".//legs[@torso='lower']/leg[@side='left']/..")
    assert elem is not None
    assert elem.name == "legs"

    # Find node with `class="body-part-group"` that has a child `ear`
    elem = doc.xpath_find(".//*[@class='body-part-group']/ear")
    assert elem is not None and elem.name == "ear"


def test_xpath_invalid_queries() -> None:
    doc = Document()
    doc.load_string(XML_DOCUMENT)
    root = doc.get_root()
    assert root is not None

    with pytest.raises(ValueError) as excinfo:
        doc.xpath_find(".//[@class='body-part-group']/ear")
    assert "Unrecognized node test" in str(excinfo.value)


def test_xpath_nonexistent_node() -> None:
    doc = Document()
    doc.load_string(XML_DOCUMENT)
    root = doc.get_root()
    assert root is not None

    # Query for a node that does not exist
    elem = doc.xpath_find(".//nonexistent")
    assert elem is None


def test_xpath_multiple_nodes() -> None:
    doc = Document()
    doc.load_string(XML_DOCUMENT)
    root = doc.get_root()
    assert root is not None

    # Query for multiple nodes
    elems = doc.xpath_findall(".//ear")
    assert all(elem.name == "ear" for elem in elems)

    # Query for multiple nodes with a specific attribute
    elems = doc.xpath_findall(".//ear[@side='left']")
    assert all(elem.name == "ear" and elem.attributes["side"] == "left" for elem in elems)

    # Query for all body parts
    elems = doc.xpath_findall(".//*[@class='body-part']")
    assert all(elem.attributes["class"] == "body-part" for elem in elems)
    body_part_tags = ("head", "ear", "leg", "torso")
    assert all(elem.name in body_part_tags for elem in elems)

    # Query for all nodes with `side="left"`
    elems = doc.xpath_findall(".//*[@side='left']")
    assert all(elem.attributes["side"] == "left" for elem in elems)
    symetric_body_part_tags = ("ear", "leg")
    assert all(elem.name in symetric_body_part_tags for elem in elems)
