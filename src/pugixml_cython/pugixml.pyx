# cython: language_level=3
# distutils: language = c++
# distutils: sources = src/pugixml_cython/extern/pugixml/src/pugixml.cpp
cimport cython

from cython.operator cimport dereference as deref, preincrement as inc




cdef int _build_node_text(NodeStruct* node_struct, xml_node* node) except -1 nogil:
    cdef xml_text text_node# = node.text()
    if node.empty():
        node_struct.has_text = False
        node_struct.text = NULL
        return 0
    child = node.first_child()

    if child.type() != node_pcdata:
    # if text_node.empty():
        node_struct.has_text = False
        node_struct.text = NULL
    else:
        node_struct.has_text = True
        # node_struct.text = text_node.get()
        text_node = node.text()
        node_struct.text = text_node.get()
    return 0

cdef int _init_node_struct(NodeStruct* node_struct) except -1 nogil:
    node_struct.type = node_null
    node_struct.name = cpp_string()
    node_struct.path = cpp_string()
    node_struct.attribute_map.clear()
    node_struct.is_empty = True
    node_struct.has_text = False
    node_struct.nest_level = 0
    node_struct.hash_value = 0
    node_struct.text = NULL
    # node_struct.parent = NULL
    # node_struct.children.clear()
    return 0

cdef int _fill_node_struct(
    NodeStruct* node_struct,
    xml_node* node,
    size_t nest_level
    # NodeStruct* parent_struct = NULL
) except -1 nogil:
    node_struct.type = node.type()
    node_struct.name = cpp_string(node.name())
    node_struct.path = cpp_string(node.path())
    node_struct.is_empty = node.empty()
    node_struct.hash_value = node.hash_value()
    node_struct.nest_level = nest_level
    # if parent_struct != NULL:
    #     node_struct.nest_level = parent_struct.nest_level + 1
    # else:
    #     node_struct.nest_level = 0
    # node_struct.parent = parent_struct
    _build_node_text(node_struct, node)

    cdef xml_attribute attr
    cdef xml_node.attribute_iterator attr_iter = node.attributes_begin()
    cdef cpp_string_pair attr_pair
    node_struct.attribute_map.clear()
    while attr_iter != node.attributes_end():
        attr = deref(attr_iter)
        attr_pair.first = attr.name()
        attr_pair.second = attr.value()
        node_struct.attribute_map[attr_pair.first] = attr_pair.second
        inc(attr_iter)
    return 0




cdef dict _attribute_map_to_dict(cpp_string_map& attribute_map):
    cdef dict result = {}
    for pair in attribute_map:
        result[pair.first.decode('utf-8')] = pair.second.decode('utf-8')
    return result




cdef bint node_type_is_excluded(xml_node_type value, xml_node_type_set* excluded_node_types) noexcept nogil:
    # if value == node_null:
    #     return True
    # if value == node_pcdata:
    #     return True
    if excluded_node_types[0].find(value) != excluded_node_types[0].end():
        return True
    return False


cdef class Document:
    """An XML document loader and handler class
    """
    def __cinit__(self):
        self._has_document = False

    def __init__(self):
        self._root_element = Element()
        self._nodes_by_hash_value = {}

    cdef int _reset(self) except -1 nogil:
        if self._has_root():
            with gil:
                self._nodes_by_hash_value.clear()
                self._root_element._clear()
        self._has_document = False
        self.doc.reset()
        return 0

    cdef int _load_string(self, const char_t* xml_string) except -1 nogil:
        self._reset()
        cdef xml_parse_result result = self.doc.load_string(xml_string)

        cdef cpp_string error_message
        if result.status != status_ok:
            error_message = result.description()
            with gil:
                raise RuntimeError(error_message.decode('utf-8'))
        self._has_document = True
        return 0

    def add_node_type_exclusion(self, node_type: NodeType) -> None:
        """Add a node type to the set of excluded node types
        """
        cdef xml_node_type value = node_type_cast(node_type)
        if self._excluded_node_types.find(value) == self._excluded_node_types.end():
            self._excluded_node_types.insert(value)

    def set_node_type_exclusions(self, node_types: list[NodeType]) -> None:
        """Set the node type exclusions to the given list of node types
        """
        cdef xml_node_type value
        self._excluded_node_types.clear()
        for node_type in node_types:
            value = node_type_cast(node_type)
            if self._excluded_node_types.find(value) == self._excluded_node_types.end():
                self._excluded_node_types.insert(value)

    def load_string(self, str xml_string not None) -> None:
        """Load an XML string into the document

        This method only parses the document.
        To access the root element, use the :meth:`get_root` method.

        Args:
            xml_string: The XML string to load into the document.
        """
        self._load_string(xml_string.encode('utf-8'))

    def clear(self) -> None:
        """Clear the XML document, resetting it to an empty state
        """
        self._reset()

    cdef bint _has_root(self) except -1 nogil:
        if not self._has_document:
            return False
        return not self._root_element._is_null()

    @property
    def has_document(self) -> bool:
        """Whether an XML document is currently loaded
        """
        return self._has_document

    @property
    def has_root(self) -> bool:
        """Whether the root element has been built
        (using the :meth:`get_root` method)
        """
        return self._has_root()

    cdef Element _get_root(self):
        if not self._has_document:
            return None
        if self._has_root():
            return self._root_element

        cdef xml_node root_node = self.doc.document_element()
        self._root_element = Element._create(&root_node, &self._excluded_node_types)
        return self._root_element

    def get_root(self) -> Element | None:
        """Get the root element of the currently-loaded XML document.

        Returns:
            The root :class:`Element` if it exists, otherwise None.
        """
        return self._get_root()

    cdef int _collect_nodes_by_hash_value(self) except -1:
        if not self._has_document:
            return 0
        cdef Element root = self._get_root(), element
        self._nodes_by_hash_value.clear()
        for element in root.walk():
            self._nodes_by_hash_value[element.node_struct.hash_value] = element
        return 0

    cdef Element _find_from_hash_value(self, size_t hash_value):
        if not self._has_document:
            return None
        if not len(self._nodes_by_hash_value):
            self._collect_nodes_by_hash_value()

        return self._nodes_by_hash_value.get(hash_value, None)

    cdef int _xpath_find(self, const char_t* xpath, NodeStruct* node_struct) except -1 nogil:

        # if not self._has_document:
        #     return None

        cdef xpath_node xresult = self.doc.select_node(xpath)
        cdef xml_node node = xresult.node()
        # if node.type() == xml_node_type.node_null:
        #     return None

        # cdef size_t hash_value = node.hash_value()
        # return self._find_from_hash_value(hash_value)
        _fill_node_struct(node_struct=node_struct, node=&node, nest_level=0)
        return 0

    def xpath_find(self, str xpath not None) -> Element | None:
        """Find the first element matching the given XPath expression

        Args:
            xpath: The XPath expression to evaluate.

        Returns:
            The first :class:`Element` matching the XPath expression,
            or None if no match is found.
        """
        if not self._has_document:
            return None
        cdef NodeStruct node_struct
        self._xpath_find(xpath.encode('utf-8'), &node_struct)
        if node_struct.type == xml_node_type.node_null:
            return None
        cdef size_t hash_value = node_struct.hash_value
        return self._find_from_hash_value(hash_value)

    cdef int _xpath_findall(self, const char_t* xpath, vector[NodeStruct*]* results) except -1 nogil:
        cdef xpath_node_set xresults = self.doc.select_nodes(xpath)
        cdef xpath_node xresult
        cdef xml_node node
        cdef NodeStruct* node_struct
        for xresult in xresults:
            node = xresult.node()
            if node.type() == xml_node_type.node_null:
                continue
            node_struct = new NodeStruct()
            _fill_node_struct(node_struct=node_struct, node=&node, nest_level=0)
            results[0].push_back(node_struct)
        return 0

    def xpath_findall(self, str xpath not None) -> list[Element]:
        """Find all elements matching the given XPath expression.

        Args:
            xpath: The XPath expression to evaluate.

        Returns:
            A list of :class:`Element` instances matching the XPath expression.
        """
        cdef vector[NodeStruct*] results
        self._xpath_findall(xpath.encode('utf-8'), &results)
        cdef list elements = []
        for node_struct in results:
            elements.append(self._find_from_hash_value(node_struct.hash_value))
        return elements




cdef class Element:
    """A single XML element within the document.

    This class represents an individual XML element and provides access
    to its attributes, children, and other properties.

    It supports iteration over its child elements,
    subscript access and :func:`len` checks:

    >>> for child in element:
    >>>     ...
    >>> child = element[0]  # Access the first child element
    >>> length = len(element)  # Get the number of child elements

    .. note::
        This class is not intended to be instantiated directly by users;
        it is created and managed internally by the XML document structure.

    """
    def __cinit__(self):
        self._position.index = 0
        self._position.nest_level = 0
        self._position.parent = NULL
        self._parent = None
        self._children_count = 0
        self._children = []
        _init_node_struct(&self.node_struct)
        self._position_indices.clear()

    def __dealloc__(self):
        # self.node_struct.parent = NULL
        # self.node_struct.children.clear()
        self._position.parent = NULL
        self._parent = None
        self.node_struct.attribute_map.clear()

    @staticmethod
    cdef Element _create(
        xml_node* node,
        xml_node_type_set* excluded_node_types,
        Element parent = None
    ):
        cdef Element self = Element()

        self._initialize_node_struct(node, excluded_node_types, parent)
        self._parent = parent
        return self

    cdef int _initialize_node_struct(
        self,
        xml_node* node,
        xml_node_type_set* excluded_node_types,
        Element parent = None
    ) except -1:
        cdef size_t nest_level
        if parent is not None:
            nest_level = parent.node_struct.nest_level + 1
            self._position.parent = &parent._position
        else:
            nest_level = 0
            self._position.parent = NULL
            self._position_indices.push_back(0)
        self._position.nest_level = nest_level
        # This will be filled in `_build_children`
        self._position.index = 0
        _fill_node_struct(&self.node_struct, node, nest_level=nest_level)
        self._build_children(node, excluded_node_types)
        return 0

    cdef int _build_children(
        self,
        xml_node* node,
        xml_node_type_set* excluded_node_types
    ) except -1:

        # _build_node_struct(&self.node_struct, node, parent)
        cdef xml_node* child
        cdef NodeStruct* child_node_struct
        cdef Element child_element
        # cdef cpp_map[size_t, xml_node*] xml_children_by_hash
        cdef xml_node_type child_type
        cdef xml_node.iterator node_iter = node.begin()
        cdef size_t child_index = 0
        while node_iter != node.end():
            child = &deref(node_iter)
            child_type = child.type()
            if child.empty():
                inc(node_iter)
                continue
            # if child_type != node_element:
            #     inc(node_iter)
            #     continue
            if child_type == node_pcdata:
                inc(node_iter)
                continue
            if node_type_is_excluded(child_type, excluded_node_types):
                inc(node_iter)
                continue
            child_element = Element._create(child, excluded_node_types, self)
            child_element._position.index = child_index
            for pos_index in self._position_indices:
                child_element._position_indices.push_back(pos_index)
            child_element._position_indices.push_back(child_index)
            self._children.append(child_element)
            inc(node_iter)
            child_index += 1
        self._children_count = child_index
        return 0

    cdef int _clear(self) except -1 nogil:
        if self._children_count > 0:
            with gil:
                self._children.clear()
        self._position.index = 0
        self._position.nest_level = 0
        _init_node_struct(&self.node_struct)
        self._children_count = 0
        self._position_indices.clear()
        return 0

    @property
    def type(self) -> NodeType:
        """The type of the XML node as a :class:`NodeType`
        """
        # return node_type_uncast(self.node_struct.type)
        return self._get_type()

    cdef NodeType _get_type(self) noexcept nogil:
        return node_type_uncast(self.node_struct.type)

    @property
    def parent(self) -> 'Element' | None:
        """The parent element of this node, or None if it has no parent
        """
        return self._parent

    @property
    def root(self) -> 'Element':
        """The root element of the XML tree
        """
        return self._get_root()

    cdef Element _get_root(self):
        cdef Element element = self
        while element._parent is not None:
            element = element._parent
        return element

    @property
    def name(self) -> str:
        """The tag name of the XML node
        """
        return self.node_struct.name.decode('utf-8')

    @property
    def path(self) -> str:
        """The full path of the XML node in the tree (delimited by slashes)
        """
        return self.node_struct.path.decode('utf-8')

    @property
    def text(self) -> str | None:
        """The text content of the XML node, or None if it has no text
        """
        if not self.node_struct.has_text:
            return None
        return self.node_struct.text.decode('utf-8')

    @property
    def is_empty(self) -> bint:
        """Whether the XML node is empty (has no children and no text)
        """
        return self.node_struct.is_empty

    @property
    def is_null(self) -> bint:
        """Whether the XML node is null (does not exist)
        """
        return self._is_null()

    cdef bint _is_null(self) noexcept nogil:
        return self.node_struct.type == node_null

    @property
    def has_text(self) -> bint:
        """Whether the XML node has text content
        """
        return self.node_struct.has_text

    @property
    def hash_value(self) -> size_t:
        """A unique hash value of the XML node
        """
        return self.node_struct.hash_value

    @property
    def attributes(self) -> dict:
        """A dictionary of the XML node's attributes
        """
        return _attribute_map_to_dict(self.node_struct.attribute_map)

    @property
    def node_position(self) -> tuple[int, ...]:
        """The position of the node in the tree as a tuple of
        indices from the root to this node

        The root node will always be represented by a single zero: ``(0,)``.
        Each subsequent index represents the position of the node among its siblings at that level.
        """
        return tuple(self._position_indices)


    def find_from_position(self, position: tuple[int, ...]) -> "Element"|None:
        """Find a node in the tree based on its :attr:`node_position`
        """
        cdef Element element = self._get_root()
        for index in position[1:]:
            if index < 0 or index >= len(element._children):
                return None
            element = element._children[index]
        return element

    def walk(self):
        """Yield all nodes in the subtree rooted at this node, including itself
        """
        yield self
        for child in self._children:
            yield from child.walk()

    def __iter__(self):
        for child in self._children:
            yield child

    def __len__(self) -> int:
        return len(self._children)

    def __getitem__(self, index: int):
        return self._children[index]

    def __repr__(self):
        return f"<Element name={self.name!r} attributes={self.attributes!r} text={self.text!r}>"
