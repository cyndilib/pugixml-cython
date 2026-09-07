from __future__ import annotations

from collections.abc import Iterator
from dataclasses import dataclass
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    from faker import Faker
    from pytest_codspeed import BenchmarkFixture


from pugixml_cython import Document, Element


@pytest.fixture(scope="session", autouse=True)
def faker_seed() -> int:
    """Provide a fixed seed for the Faker instance
    """
    return 42


@pytest.fixture(scope="session", autouse=True)
def faker_locale() -> str:
    """Provide a fixed locale for the Faker instance
    """
    return "en_US"



@pytest.fixture
def xml_node_with_multiple_attributes(faker: Faker) -> XmlNode:
    """Provide a single XmlNode with many attributes
    """
    num_levels = 1
    children_per_level = 3
    attrs_per_node = 128
    return XmlNode.create(faker, num_levels, children_per_level, attrs_per_node)


@pytest.fixture
def xml_node_with_multiple_children(faker: Faker) -> XmlNode:
    """Provide a large tree of XmlNode instances
    """
    num_levels = 5
    children_per_level = 3
    attrs_per_node = 4
    return XmlNode.create(faker, num_levels, children_per_level, attrs_per_node)



@dataclass
class XmlNode:
    """Helper class to build and check XML nodes
    """
    name: str
    """The tag name of the XML node"""
    attributes: dict[str, str]
    """The attributes of the XML node"""
    children: list[XmlNode]
    """The child nodes of the XML node"""
    parent: XmlNode | None = None
    """The parent node of the XML node, or None if it is the root."""

    @classmethod
    def create(
        cls,
        faker: Faker,
        num_levels: int,
        children_per_level: int,
        attrs_per_node: int,
        parent: XmlNode | None = None,
    ) -> XmlNode:
        """Create an XmlNode and its children recursively

        Arguments:
            faker: The Faker instance used to generate random data.
            num_levels: The number of levels of children to create.
            children_per_level: The number of children per level.
            attrs_per_node: The number of attributes per node.

        """
        # Generate a set of unique attribute keys for the node.
        # We could use faker.unique.word() to ensure uniqueness,
        # but it may raise UniquenessException if we run out of unique words.
        key_list = [faker.word() for _ in range(attrs_per_node)]
        keys = set(key_list)
        if len(keys) < attrs_per_node:
            num_to_add = attrs_per_node - len(keys)
            extra_keys = (
                f"{key}-{faker.random_letter()}" for key in list(keys)[:num_to_add]
            )
            keys.update(extra_keys)
        assert len(keys) == attrs_per_node
        attrs = {key: faker.word() for key in keys}
        if num_levels <= 0:
            return XmlNode(name=faker.word(), attributes=attrs, children=[])

        node = XmlNode(name=faker.word(), attributes=attrs, children=[], parent=parent)
        node.children = [
            cls.create(
                faker=faker,
                num_levels=num_levels - 1,
                children_per_level=children_per_level,
                attrs_per_node=attrs_per_node,
                parent=node,
            )
            for _ in range(children_per_level)
        ]
        return node

    @property
    def root(self) -> XmlNode:
        """The root node of the XML tree
        """
        if self.parent is None:
            return self
        return self.parent.root

    @property
    def nest_level(self) -> int:
        """Return the nesting level of the current node in the XML tree
        """
        if self.parent is None:
            return 0
        return self.parent.nest_level + 1

    def get_max_nest_level(self) -> int:
        """Return the maximum nesting level of any node in the XML tree starting
        from the current node
        """
        return max(child.nest_level for child in self.walk())

    def count_all(self) -> int:
        """Count the total number of nodes in the XML tree, including the current node
        """
        return 1 + sum(child.count_all() for child in self.children)

    def render(self, indent: int = 0) -> str:
        """Render the current node and its children as an XML string with indentation

        Arguments:
            indent: The number of spaces to use for indentation.
        """
        open_tag = self._open_tag(indent)
        children = f"{self._render_children(indent + 4)}"
        close_tag = self._close_tag(indent)
        return f"{open_tag}\n{children}\n{close_tag}"

    def _open_tag(self, indent: int = 0) -> str:
        indent_str = ' ' * indent
        attrs_str = ' '.join(f'{key}="{value}"' for key, value in self.attributes.items())
        return f"{indent_str}<{self.name} {attrs_str}>"

    def _render_children(self, indent: int = 0) -> str:
        return '\n'.join(child.render(indent + 2) for child in self.children)

    def _close_tag(self, indent: int = 0) -> str:
        indent_str = ' ' * indent
        return f"{indent_str}</{self.name}>"

    def deepest_nodes(self) -> Iterator[XmlNode]:
        """Yield all nodes in the XML tree that have the maximum nesting level
        starting from the current node
        """
        max_nest_level = self.get_max_nest_level()
        for node in self.walk():
            if node.nest_level == max_nest_level:
                yield node

    def check(self, element: Element) -> None:
        """Check if the given XML element matches the current XmlNode recursively
        """
        assert element.name == self.name
        assert element.attributes == self.attributes
        assert len(element) == len(self.children)
        for child_node, child_element in zip(self.children, element):
            child_node.check(child_element)

    def get_xpath_query(self) -> str:
        """Return the XPath of the current node
        """
        if self.parent is None:
            return f"/{self.name}"
        return f"{self.parent.get_xpath_query()}/{self.name}"

    def get_xpath_query_with_attributes(self) -> str:
        """Return the XPath of the current node including its attributes"""
        xpath = self.get_xpath_query()
        if self.attributes:
            for key, value in self.attributes.items():
                xpath += f'[@{key}="{value}"]'
        return xpath

    def walk(self) -> Iterator[XmlNode]:
        """Yield all nodes in the XML tree starting from the current node
        """
        yield self
        for child in self.children:
            yield from child.walk()




def test_xml_with_multi_attributes(
    benchmark: BenchmarkFixture,
    xml_node_with_multiple_attributes: XmlNode,
) -> None:
    """Benchmark test for XML parsing with many attributes, but fewer children
    """
    src_root_node = xml_node_with_multiple_attributes
    doc = Document()
    xml_string = src_root_node.render()

    # Pre-load the XML string into the document so it doesn't alter the benchmark results
    # (Document calls its clear method internally when loading a new string)
    doc.load_string(xml_string)

    def run_benchmark() -> None:
        doc.load_string(xml_string)
        root = doc.get_root()
        assert root is not None

    benchmark(run_benchmark)

    # Returning from the benchmark function would not work because pytest_codspeed
    # stores the result of the first run only, which would have been cleared in subsequent runs.
    #
    # The last parse result is preserved in the document, so we can retrieve it here.
    root_element = doc.get_root()
    assert root_element is not None

    src_root_node.check(root_element)




def test_xml_nodes_with_multiple_children(
    benchmark: BenchmarkFixture,
    xml_node_with_multiple_children: XmlNode,
) -> None:
    """Benchmark test for XML parsing with many deeply-nested children, but fewer attributes
    """
    src_root_node = xml_node_with_multiple_children
    xml_string = src_root_node.render()
    doc = Document()

    # Pre-load the XML string into the document so it doesn't alter the benchmark results
    # (Document calls its clear method internally when loading a new string)
    doc.load_string(xml_string)

    def run_benchmark() -> None:
        doc.load_string(xml_string)
        root = doc.get_root()
        assert root is not None

    benchmark(run_benchmark)

    # Returning from the benchmark function would not work because pytest_codspeed
    # stores the result of the first run only, which would have been cleared in subsequent runs.
    #
    # The last parse result is preserved in the document, so we can retrieve it here.
    root_element = doc.get_root()
    assert root_element is not None
    src_root_node.check(root_element)



@pytest.mark.parametrize("with_attributes", [False, True])
def test_xpath_deep_search(
    benchmark: BenchmarkFixture,
    xml_node_with_multiple_children: XmlNode,
    with_attributes: bool,
) -> None:
    """Benchmark test for deep XPath searches in XML documents

    This test is parameterized to run with and without attributes in the XPath queries.
    """
    src_root_node = xml_node_with_multiple_children
    xml_string = src_root_node.render()
    doc = Document()
    doc.load_string(xml_string)

    # Find the deepest nodes in the source XML tree and prepare their XPath queries
    deepest_nodes: list[tuple[XmlNode, str]] = []
    for node in src_root_node.deepest_nodes():
        if with_attributes:
            xpath = node.get_xpath_query_with_attributes()
        else:
            xpath = node.get_xpath_query()
        deepest_nodes.append((node, xpath))

    # Pre-build the element tree to avoid including its construction in the benchmark
    doc.get_root()

    def run_benchmark() -> None:
        for node, xpath in deepest_nodes:
            element = doc.xpath_find(xpath)

            # We're only checking the node name here to avoid excessive overhead.
            assert element is not None
            assert element.name == node.name

    benchmark(run_benchmark)
