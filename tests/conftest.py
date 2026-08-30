from pathlib import Path
from typing import NamedTuple, Self

import pytest

from pugixml_cython import Element

HERE = Path(__file__).parent
DATA_DIR = HERE / "data"


class XmlResult(NamedTuple):
    """Represents the expected structure of an XML element for testing purposes.
    """
    tag: str
    """The tag name of the XML element"""
    text: str | None
    """The text content of the XML element, or None if it has no text"""
    attrib: dict[str, str]
    """The attributes of the XML element as a dictionary of name-value pairs"""
    children: list[Self]
    """The list of expected child elements"""

    def check(self, element: Element, recurse: bool = True) -> None:
        """Check that the given XML element matches the expected structure.

        Args:
            element: The XML element to check.
            recurse: Whether to recursively check child elements.
        """
        assert element.name == self.tag
        assert element.text == self.text
        if self.text is None:
            assert not element.has_text
        else:
            assert element.has_text

        assert element.attributes == self.attrib
        if not recurse:
            return

        assert len(element) == len(self.children)

        for i, expected_child in enumerate(self.children):
            child_element = element[i]
            # check_element(child_element, expected_child, recurse=recurse)
            expected_child.check(child_element, recurse=recurse)


class XmlTestCase(NamedTuple):
    """Represents a test case for XML parsing, including the XML content and
    the expected result.
    """

    xml: str | Path
    """The XML content as a string or a Path to an XML file"""
    expected: XmlResult
    """The expected structure of the XML content"""


SAMPLE_XML = """\
<body>
  <tag class='a'>text</tag>
  <tag class='b' />
  <section>
    <tag class='b' id='inner'>subtext</tag>
  </section>
</body>
"""

SAMPLE_XML_TEST_CASE = XmlTestCase(
    xml=SAMPLE_XML,
    expected=XmlResult(
        tag="body",
        text=None,
        attrib={},
        children=[
            XmlResult(tag="tag", text="text", attrib={"class": "a"}, children=[]),
            XmlResult(tag="tag", text=None, attrib={"class": "b"}, children=[]),
            XmlResult(
                tag="section",
                text=None,
                attrib={},
                children=[
                    XmlResult(tag="tag", text="subtext", attrib={"class": "b", "id": "inner"}, children=[])
                ],
            ),
        ],
    ),
)

SAMPLE_SECTION = """\
<section>
  <tag class='b' id='inner'>subtext</tag>
  <nexttag />
  <nextsection>
    <tag />
  </nextsection>
</section>
"""

SAMPLE_SECTION_TEST_CASE = XmlTestCase(
    xml=SAMPLE_SECTION,
    expected=XmlResult(
        tag="section",
        text=None,
        attrib={},
        children=[
            XmlResult(tag="tag", text="subtext", attrib={"class": "b", "id": "inner"}, children=[]),
            XmlResult(tag="nexttag", text=None, attrib={}, children=[]),
            XmlResult(
                tag="nextsection",
                text=None,
                attrib={},
                children=[
                    XmlResult(tag="tag", text=None, attrib={}, children=[])
                ],
            ),
        ],
    ),
)

SAMPLE_XML_NS = """
<body xmlns="http://effbot.org/ns">
  <tag>text</tag>
  <tag />
  <section>
    <tag>subtext</tag>
  </section>
</body>
"""

SAMPLE_XML_NS_TEST_CASE = XmlTestCase(
    xml=SAMPLE_XML_NS,
    expected=XmlResult(
        tag="body",
        text=None,
        attrib={"xmlns": "http://effbot.org/ns"},
        children=[
            XmlResult(tag="tag", text="text", attrib={}, children=[]),
            XmlResult(tag="tag", text=None, attrib={}, children=[]),
            XmlResult(
                tag="section",
                text=None,
                attrib={},
                children=[
                    XmlResult(tag="tag", text="subtext", attrib={}, children=[])
                ],
            ),
        ],
    ),
)

SAMPLE_XML_NS_ELEMS = """
<root>
<h:table xmlns:h="hello">
  <h:tr>
    <h:td>Apples</h:td>
    <h:td>Bananas</h:td>
  </h:tr>
</h:table>

<f:table xmlns:f="foo">
  <f:name>African Coffee Table</f:name>
  <f:width>80</f:width>
  <f:length>120</f:length>
</f:table>
</root>
"""

SAMPLE_XML_NS_ELEMS_TEST_CASE = XmlTestCase(
    xml=SAMPLE_XML_NS_ELEMS,
    expected=XmlResult(
        tag="root",
        text=None,
        attrib={},
        children=[
            XmlResult(
                tag="h:table",
                text=None,
                attrib={"xmlns:h": "hello"},
                children=[
                    XmlResult(
                        tag="h:tr",
                        text=None,
                        attrib={},
                        children=[
                            XmlResult(tag="h:td", text="Apples", attrib={}, children=[]),
                            XmlResult(tag="h:td", text="Bananas", attrib={}, children=[]),
                        ],
                    )
                ],
            ),
            XmlResult(
                tag="f:table",
                text=None,
                attrib={"xmlns:f": "foo"},
                children=[
                    XmlResult(tag="f:name", text="African Coffee Table", attrib={}, children=[]),
                    XmlResult(tag="f:width", text="80", attrib={}, children=[]),
                    XmlResult(tag="f:length", text="120", attrib={}, children=[]),
                ],
            ),
        ],
    ),
)

ENTITY_XML = """\
<!DOCTYPE points [
<!ENTITY % user-entities SYSTEM 'user-entities.xml'>
%user-entities;
]>
<document>&entity;</document>
"""

ENTITY_XML_TEST_CASE = XmlTestCase(
    xml=ENTITY_XML,
    expected=XmlResult(
        tag="document",
        text="&entity;",
        attrib={},
        children=[],
    ),
)

EXTERNAL_ENTITY_XML = """\
<!DOCTYPE points [
<!ENTITY entity SYSTEM "file:///non-existing-file.xml">
]>
<document>&entity;</document>
"""

EXTERNAL_ENTITY_XML_TEST_CASE = XmlTestCase(
    xml=EXTERNAL_ENTITY_XML,
    expected=XmlResult(
        tag="document",
        text="&entity;",
        attrib={},
        children=[],
    ),
)

ATTLIST_XML = """\
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE Foo [
<!ELEMENT foo (bar*)>
<!ELEMENT bar (#PCDATA)*>
<!ATTLIST bar xml:lang CDATA "eng">
<!ENTITY qux "quux">
]>
<foo>
<bar>&qux;</bar>
</foo>
"""

ATTLIST_XML_TEST_CASE = XmlTestCase(
    xml=ATTLIST_XML,
    expected=XmlResult(
        tag="foo",
        text=None,
        attrib={},
        children=[
            XmlResult(
                tag="bar",
                text="&qux;",
                attrib={},
                children=[]
            )
        ],
    ),
)



XML_FILE_SIMPLE_TEST_CASE = XmlTestCase(
    xml=DATA_DIR / "simple.xml",
    expected=XmlResult(
        tag="root",
        text="tail",
        attrib={},
        children=[
            XmlResult(tag="element", text="text", attrib={"key": "value"}, children=[]),
            XmlResult(tag="element", text="text", attrib={}, children=[]),
            XmlResult(tag="empty-element", text=None, attrib={}, children=[]),
        ],
    ),
)

_text_xml_file_expected = XmlResult(
    tag="HTML",
    text=None,
    attrib={},
    children=[
        XmlResult(tag="TITLE", text="Introduction to XSL", attrib={}, children=[]),
        XmlResult(tag="H1", text="Introduction to XSL", attrib={}, children=[]),
        XmlResult(tag="HR", text=None, attrib={}, children=[]),
        XmlResult(tag="H2", text="Overview", attrib={}, children=[]),
        XmlResult(tag="UL", text=None, attrib={}, children=[
            XmlResult(tag="LI", text="1.Intro", attrib={}, children=[]),
            XmlResult(tag="LI", text="2.History", attrib={}, children=[]),
            XmlResult(tag="LI", text="3.XSL Basics", attrib={}, children=[]),
            XmlResult(tag="LI", text="Lunch", attrib={}, children=[]),
            XmlResult(tag="LI", text="4.An XML Data Model", attrib={}, children=[]),
            XmlResult(tag="LI", text="5.XSL Patterns", attrib={}, children=[]),
            XmlResult(tag="LI", text="6.XSL Templates", attrib={}, children=[]),
            XmlResult(tag="LI", text="7.XSL Formatting Model", attrib={}, children=[]),
        ]),
        XmlResult(tag="HR", text=None, attrib={}, children=[]),
        XmlResult(tag="H2", text="History: FOSI", attrib={}, children=[]),
        XmlResult(tag="UL", text=None, attrib={}, children=[
            XmlResult(tag="LI", text="FOSI: &quot;Formatted Output Specification Instance&quot;", attrib={}, children=[
                XmlResult(tag="UL", text=None, attrib={}, children=[
                    XmlResult(tag="LI", text="MIL-STD-28001", attrib={}, children=[]),
                    XmlResult(tag="LI", text="FOSI's are SGML documents", attrib={}, children=[]),
                    XmlResult(tag="LI", text="A stylesheet for another document", attrib={}, children=[]),
                ]),
            ]),
            XmlResult(tag="LI", text="Obsolete but implemented...", attrib={}, children=[]),
        ]),
    ],
)


# TODO: "auto" encoding only works with the
# `doc.load_buffer methods`` (not currently implemented)
# XML_FILE_TEST_TEST_CASE = XmlTestCase(
#     xml=DATA_DIR / "test.xml",
#     # xml=_text_dot_xml_file_contents,
#     expected=_text_xml_file_expected
# )

# XML_FILE_TEST_OUT_CASE = XmlTestCase(
#     xml=DATA_DIR / "test.xml.out",
#     # xml=_text_dot_xml_file_contents,
#     expected=_text_xml_file_expected
# )




@pytest.fixture(
    params=[
        SAMPLE_XML_TEST_CASE,
        SAMPLE_SECTION_TEST_CASE,
        SAMPLE_XML_NS_TEST_CASE,
        SAMPLE_XML_NS_ELEMS_TEST_CASE,
        ENTITY_XML_TEST_CASE,
        EXTERNAL_ENTITY_XML_TEST_CASE,
        ATTLIST_XML_TEST_CASE,
        # XML_FILE_TEST_TEST_CASE,
        # XML_FILE_TEST_OUT_CASE,
    ],
    ids=[
        "SAMPLE_XML_TEST_CASE",
        "SAMPLE_SECTION_TEST_CASE",
        "SAMPLE_XML_NS_TEST_CASE",
        "SAMPLE_XML_NS_ELEMS_TEST_CASE",
        "ENTITY_XML_TEST_CASE",
        "EXTERNAL_ENTITY_XML_TEST_CASE",
        "ATTLIST_XML_TEST_CASE",
        # "XML_FILE_TEST_TEST_CASE",
        # "XML_FILE_TEST_OUT_CASE",
    ]
)
def xml_test_case(request: pytest.FixtureRequest) -> XmlTestCase:
    """Fixture that provides XML test cases for parameterized tests.
    """
    return request.param
