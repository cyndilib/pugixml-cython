
from libcpp.exception cimport exception, runtime_error, delegate_to_exception_handlers
from libcpp.string cimport string as cpp_string

ctypedef char char_t
ctypedef cpp_string string_t



# Handlers for individual exceptions
cdef inline void handle_xpath_exception(const xpath_exception& e) except*:
    raise ValueError(e.what().decode("ascii"))

cdef inline void handle_runtime_error(const runtime_error& e) except*:
    raise RuntimeError(e.what().decode("ascii"))

cdef inline void handle_anything(const exception& e) except*:
    try:
        msg = e.what().decode("ascii")
    except:
        msg = "Unknown error"
    raise Exception(msg)  # Raise a generic exception for any other errors

# Overall exception handler mechanism
cdef inline void custom_exception_handler() except*:
    delegate_to_exception_handlers(handle_xpath_exception, handle_runtime_error, handle_anything)


cdef extern from "pugixml.hpp" namespace "pugi" nogil:
    cdef enum xml_node_type:
        node_null			# Empty (null) node handle
        node_document		# A document tree's absolute root
        node_element		# Element tag, i.e. '<node/>'
        node_pcdata		    # Plain character data, i.e. 'text'
        node_cdata			# Character data, i.e. '<![CDATA[text]]>'
        node_comment		# Comment tag, i.e. '<!-- text -->'
        node_pi  		    # Processing instruction, i.e. '<?name?>'
        node_declaration	# Document declaration, i.e. '<?xml version="1.0"?>'
        node_doctype		# Document type declaration, i.e. '<!DOCTYPE doc>'

    cdef enum xml_encoding:
        encoding_auto		# Auto-detect input encoding using BOM or < / <? detection; use UTF8 if BOM is not found
        encoding_utf8		# UTF8 encoding
        encoding_utf16_le	# Little-endian UTF16
        encoding_utf16_be	# Big-endian UTF16
        encoding_utf16		# UTF16 with native endianness
        encoding_utf32_le	# Little-endian UTF32
        encoding_utf32_be	# Big-endian UTF32
        encoding_utf32		# UTF32 with native endianness
        encoding_wchar		# The same encoding wchar_t has (either UTF16 or UTF32)
        encoding_latin1		# Latin1 encoding (ISO-8859-1)

    cdef const unsigned int parse_default	# Default parse options
    cdef const unsigned int format_default  # Default format options

    cdef cppclass xml_writer:
        xml_writer()

        void write(const char_t* data, size_t size)


    cdef cppclass xml_attribute:
        xml_attribute()

        bint operator==(const xml_attribute& other)
        bint operator!=(const xml_attribute& other)
        bint operator<(const xml_attribute& other)
        bint operator>(const xml_attribute& other)
        bint operator<=(const xml_attribute& other)
        bint operator>=(const xml_attribute& other)

        bint empty()  # Check if the attribute is empty

        const char_t* name()  # Get the attribute name
        const char_t* value()  # Get the attribute value

        const char_t* as_string()  # Get the attribute value as a string

        int as_int()  # Get the attribute value as an integer
        unsigned int as_uint()  # Get the attribute value as an unsigned integer
        double as_double()  # Get the attribute value as a double
        float as_float()  # Get the attribute value as a float
        long long as_llong()  # Get the attribute value as a long long
        unsigned long long as_ullong()  # Get the attribute value as an unsigned long long
        bint as_bool()  # Get the attribute value as a boolean


        bint set_name(const char_t* name)  # Set the attribute name
        bint set_name(const char_t* name, size_t size)  # Set the attribute name with a specified size

        bint set_value(const char_t* value)
        bint set_value(const char_t* value, size_t size)
        bint set_value(int value)
        bint set_value(unsigned int value)
        bint set_value(double value)
        bint set_value(float value)
        bint set_value(long long value)
        bint set_value(unsigned long long value)
        bint set_value(bint value)

        xml_attribute next_attribute()  # Get the next attribute of the node
        xml_attribute previous_attribute()  # Get the previous attribute of the node

        size_t hash_value()  # Get the hash value of the attribute


    cdef cppclass xml_node:
        xml_node()

        bint operator==(const xml_node& other)
        bint operator!=(const xml_node& other)
        bint operator<(const xml_node& other)
        bint operator>(const xml_node& other)
        bint operator<=(const xml_node& other)
        bint operator>=(const xml_node& other)

        bint empty()  # Check if the node is empty
        xml_node_type type()  # Get the node type
        const char_t* name()  # Get the node name
        const char_t* value()  # Get the node value

        xml_attribute first_attribute()  # Get the first attribute of the node
        xml_attribute last_attribute()  # Get the last attribute of the node

        xml_node first_child()  # Get the first child of the node
        xml_node last_child()  # Get the last child of the node

        xml_node next_sibling()  # Get the next sibling of the node
        xml_node previous_sibling()  # Get the previous sibling of the node

        xml_node parent()  # Get the parent of the node

        xml_node root()  # Get the root of the node

        xml_text text()  # Get the text of the node

        # Get child, attribute or next/previous sibling with the specified name
        xml_node child(const char_t* name)  # Get the child node with the specified name
        xml_attribute attribute(const char_t* name)  # Get the attribute with the specified name
        xml_node next_sibling(const char_t* name)  # Get the next sibling with the specified name
        xml_node previous_sibling(const char_t* name)  # Get the previous sibling with the specified name

        # Get attribute, starting the search from a hint (and updating hint so that searching for a sequence of attributes is fast)
        xml_attribute attribute(const char_t* name, xml_attribute& hint)

        const char_t* child_value() # Get the value of the first child node
        const char_t* child_value(const char_t* name)  # Get the value of the child node with the specified name

        bint set_name(const char_t* name)  # Set the node name
        bint set_name(const char_t* name, size_t size)  # Set the node name with the specified size
        bint set_value(const char_t* value)  # Set the node value
        bint set_value(const char_t* value, size_t size)  # Set the node value with the specified size


        # // Add attribute with specified name. Returns added attribute, or empty attribute on errors.
        xml_attribute append_attribute(const char_t* name)
        xml_attribute prepend_attribute(const char_t* name)
        xml_attribute insert_attribute_after(const char_t* name, xml_attribute& attr)
        xml_attribute insert_attribute_before(const char_t* name, xml_attribute& attr)

        # Get attribute with specified name, adding one if it does not exist. Returns the existing or added attribute, or empty attribute on errors.
        xml_attribute ensure_attribute(const char_t* name)

        # Add a copy of the specified attribute. Returns added attribute, or empty attribute on errors.
        xml_attribute append_copy(const xml_attribute& proto)
        xml_attribute prepend_copy(const xml_attribute& proto)
        xml_attribute insert_copy_after(const xml_attribute& proto, xml_attribute& attr)
        xml_attribute insert_copy_before(const xml_attribute& proto, xml_attribute& attr)

        # Add child node with specified type. Returns added node, or empty node on errors.
        xml_node append_child(xml_node_type type)
        xml_node prepend_child(xml_node_type type)
        xml_node insert_child_after(xml_node_type type, const xml_node& node)
        xml_node insert_child_before(xml_node_type type, const xml_node& node)

        # Add child node with specified name. Returns added node, or empty node on errors.
        xml_node append_child(const char_t* name)
        xml_node prepend_child(const char_t* name)
        xml_node insert_child_after(const char_t* name, const xml_node& node)
        xml_node insert_child_before(const char_t* name, const xml_node& node)

        # Get child with specified name, adding one if it does not exist. Returns the existing or added node, or empty node on errors.
        xml_node ensure_child(const char_t* name)

        # Add a copy of the specified node as a child. Returns added node, or empty node on errors.
        xml_node append_copy(const xml_node& proto)
        xml_node prepend_copy(const xml_node& proto)
        xml_node insert_copy_after(const xml_node& proto, const xml_node& node)
        xml_node insert_copy_before(const xml_node& proto, const xml_node& node)

        # Move the specified node to become a child of this node. Returns moved node, or empty node on errors.
        xml_node append_move(xml_node& moved)
        xml_node prepend_move(xml_node& moved)
        xml_node insert_move_after(xml_node& moved, const xml_node& node)
        xml_node insert_move_before(xml_node& moved, const xml_node& node)

        # Remove specified attribute
        bint remove_attribute(const xml_attribute& attr)
        bint remove_attribute(const char_t* name)

        # Remove all attributes
        bint remove_attributes()

        # Remove specified child
        bint remove_child(const xml_node& node)
        bint remove_child(const char_t* name)

        # Remove all children
        bint remove_children()

        # Parses buffer as an XML document fragment and appends all nodes as children of the current node.
		# Copies/converts the buffer, so it may be deleted or changed after the function returns.
		# Note: append_buffer allocates memory that has the lifetime of the owning document; removing the appended nodes does not immediately reclaim that memory.
        xml_parse_result append_buffer(const void* contents, size_t size)

        # Find child node by attribute name/value
        xml_node find_child_by_attribute(const char_t* name, const char_t* attr_name, const char_t* attr_value)
        xml_node find_child_by_attribute(const char_t* attr_name, const char_t* attr_value)

        # Get the absolute node path from root as a text string (delimited by '/').
        string_t path()

        # Search for a node by path consisting of node names and . or .. elements.
        xml_node first_element_by_path(const char_t* path)

        # Recursively traverse subtree with xml_tree_walker
        bint traverse(xml_tree_walker& walker)

        # Select single node by evaluating XPath query. Returns first node from the resulting node set.
        xpath_node select_node(const char_t* xpath) except +custom_exception_handler
        xpath_node select_node(const xpath_query& query) except +custom_exception_handler

        # Select node set by evaluating XPath query
        xpath_node_set select_nodes(const char_t* xpath) except +custom_exception_handler
        xpath_node_set select_nodes(const xpath_query& query) except +custom_exception_handler

        # Print subtree using a writer object
        void print(xml_writer& writer)

        # # Print subtree to stream
        # void print(ostream_t& os)

        # Child nodes iterators
        cppclass iterator:
            iterator()
            iterator(const xml_node& node)
            bint operator==(const iterator& other)
            bint operator!=(const iterator& other)

            xml_node& operator*()
            # xml_node& operator->()

            iterator operator++()
            iterator operator++(int)
            iterator operator--()
            iterator operator--(int)

        iterator begin()
        iterator end()

        # # Attribute iterators
        cppclass attribute_iterator:
            attribute_iterator()
            # attribute_iterator(const xml_attribute& attr, const xml_node& parent)
            bint operator==(attribute_iterator)
            bint operator!=(attribute_iterator)

            xml_attribute& operator*()
            # xml_attribute& operator->()

            attribute_iterator operator++()
            attribute_iterator operator--()
            attribute_iterator operator++(int)
            attribute_iterator operator--(int)
            # attribute_iterator& operator++()
            # attribute_iterator operator++(int)
            # attribute_iterator& operator--()
            # attribute_iterator operator--(int)


        attribute_iterator attributes_begin()
        attribute_iterator attributes_end()

        # Get hash value (unique for handles to the same object)
        size_t hash_value()

    cdef cppclass xml_text:
        xml_text()

        # Check if text object is empty (null)
        bint empty()

        # Get text, or "" if object is empty
        const char_t* get()

        # Get text, or the default value (an empty string) if object is empty
        const char_t* as_string()

        # Get text as a number, or the default value if conversion did not succeed or object is empty
        int as_int()
        unsigned int as_uint()
        double as_double()
        float as_float()
        long long as_llong()
        unsigned long long as_ullong()

        # Get text as bool (returns true if first character is in '1tTyY' set), or the default value if object is empty
        bint as_bool()

        # Set text (returns false if object is empty or there is not enough memory)
        bint set(const char_t* value)
        bint set(const char_t* value, size_t size)

        # Set text with type conversion (numbers are converted to strings, boolean is converted to "true"/"false")
        bint set(int value)
        bint set(unsigned int value)
        bint set(long value)
        bint set(unsigned long value)
        bint set(double value)
        bint set(double value, int precision)
        bint set(float value)
        bint set(float value, int precision)
        bint set(bint value)
        bint set(long long value)
        bint set(unsigned long long value)

    cdef cppclass xpath_exception(exception):
        const xpath_parse_result* result()

    cdef cppclass xpath_node:
        xpath_node()

        # Get node/attribute, if any
        xml_node node()
        xml_attribute attribute()

        # Get parent of contained node/attribute
        xml_node parent()

        bint operator==(const xpath_node& other)
        bint operator!=(const xpath_node& other)


    cdef cppclass xpath_node_set:

        xpath_node_set()

        cppclass const_iterator
        cppclass iterator:
            iterator()
            iterator(const xpath_node_set& set)
            bint operator==(iterator)
            bint operator==(const_iterator)
            bint operator!=(iterator)
            bint operator!=(const_iterator)
            bint operator>(iterator)
            bint operator>(const_iterator)
            bint operator<(iterator)
            bint operator<(const_iterator)
            bint operator>=(iterator)
            bint operator>=(const_iterator)
            bint operator<=(iterator)
            bint operator<=(const_iterator)

            xpath_node& operator*()

            iterator& operator++()
            iterator operator++(int)
            iterator& operator--()
            iterator operator--(int)

        cppclass const_iterator:
            const_iterator()
            const_iterator(const xpath_node_set& set)
            bint operator==(iterator)
            bint operator==(const_iterator)
            bint operator!=(iterator)
            bint operator!=(const_iterator)
            bint operator>(iterator)
            bint operator>(const_iterator)
            bint operator<(iterator)
            bint operator<(const_iterator)
            bint operator>=(iterator)
            bint operator>=(const_iterator)
            bint operator<=(iterator)
            bint operator<=(const_iterator)

            xpath_node& operator*()

            const_iterator& operator++()
            const_iterator operator++(int)
            const_iterator& operator--()
            const_iterator operator--(int)

        # type_t type()
        size_t size()
        const xpath_node& operator[](size_t index)

        const_iterator begin()
        const_iterator end()

        xpath_node first()

        bint empty()

    cdef cppclass xpath_query:
        xpath_query()
        xpath_query(const char* query)

        # Get query expression return type
        xpath_value_type return_type()

        # Evaluate expression as boolean value in the specified context; performs type conversion if necessary.
        # If PUGIXML_NO_EXCEPTIONS is not defined, throws std::bad_alloc on out of memory errors.
        bint evaluate_boolean(const xpath_node& n)

        # Evaluate expression as double value in the specified context; performs type conversion if necessary.
        # If PUGIXML_NO_EXCEPTIONS is not defined, throws std::bad_alloc on out of memory errors.
        double evaluate_number(const xpath_node& n)

        # Evaluate expression as string value in the specified context; performs type conversion if necessary.
        # If PUGIXML_NO_EXCEPTIONS is not defined, throws std::bad_alloc on out of memory errors.
        string_t evaluate_string(const xpath_node& n)

        # Evaluate expression as string value in the specified context; performs type conversion if necessary.
        # At most capacity characters are written to the destination buffer, full result size is returned (includes terminating zero).
        # If PUGIXML_NO_EXCEPTIONS is not defined, throws std::bad_alloc on out of memory errors.
        # If PUGIXML_NO_EXCEPTIONS is defined, returns empty string instead.
        size_t evaluate_string(char_t* buffer, size_t capacity, const xpath_node& n)

        # Evaluate expression as node set in the specified context.
        # If PUGIXML_NO_EXCEPTIONS is not defined, throws xpath_exception on type mismatch and std::bad_alloc on out of memory errors.
        # If PUGIXML_NO_EXCEPTIONS is defined, returns empty node set instead.
        xpath_node_set evaluate_node_set(const xpath_node& n)

        # Evaluate expression as node set in the specified context.
        # Return first node in document order, or empty node if node set is empty.
        # If PUGIXML_NO_EXCEPTIONS is not defined, throws xpath_exception on type mismatch and std::bad_alloc on out of memory errors.
        # If PUGIXML_NO_EXCEPTIONS is defined, returns empty node instead.
        xpath_node evaluate_node(const xpath_node& n)

        # Get parsing result (used to get compilation errors in PUGIXML_NO_EXCEPTIONS mode)
        const xpath_parse_result& result()

    cdef enum xpath_value_type:
        xpath_type_none 	  # Unknown type (query failed to compile)
        xpath_type_node_set   # Node set (xpath_node_set)
        xpath_type_number	  # Number
        xpath_type_string	  # String
        xpath_type_boolean	  # Boolean

    cdef cppclass xpath_parse_result:
        xpath_parse_result()


        # Error message (0 if no error)
        const char* error

        # Last parsed offset (in char_t units from string start)
        ptrdiff_t offset

        # Cast to bool operator
        bint operator bool()

        # Get error description
        const char* description()


    cdef cppclass xml_tree_walker:
        xml_tree_walker()
        # ~xml_tree_walker()

        # Get current traversal depth
        int depth()

        # Callback that is called when traversal begins
        bint begin(xml_node& node)
        # Callback that is called for each node during traversal
        bint for_each(xml_node& node)
        # Callback that is called when traversal ends
        bint end(xml_node& node)


    cdef enum xml_parse_status:
        status_ok = 0				# No error

        status_file_not_found		# File was not found during load_file()
        status_io_error			# Error reading from file/stream
        status_out_of_memory		# Could not allocate memory
        status_internal_error		# Internal error occurred

        status_unrecognized_tag	# Parser could not determine tag type

        status_bad_pi				# Parsing error occurred while parsing document declaration/processing instruction
        status_bad_comment			# Parsing error occurred while parsing comment
        status_bad_cdata			# Parsing error occurred while parsing CDATA section
        status_bad_doctype			# Parsing error occurred while parsing document type declaration
        status_bad_pcdata			# Parsing error occurred while parsing PCDATA section
        status_bad_start_element	# Parsing error occurred while parsing start element tag
        status_bad_attribute		# Parsing error occurred while parsing element attribute
        status_bad_end_element		# Parsing error occurred while parsing end element tag
        status_end_element_mismatch # There was a mismatch of start-end tags (closing tag had incorrect name, some tag was not closed or there was an excessive closing tag)

        status_append_invalid_root	# Unable to append nodes since root type is not node_element or node_document (exclusive to xml_node::append_buffer)

        status_no_document_element	# Parsing resulted in a document without element nodes

    cdef cppclass xml_parse_result:
        xml_parse_status status
        ptrdiff_t offset
        xml_encoding encoding

        xml_parse_result()

        bint operator bool()
        const char* description()

    cdef cppclass xml_document(xml_node):
        xml_document()
        # ~xml_document()

        # Removes all nodes, leaving the empty document
        void reset()

        # Removes all nodes, then copies the entire contents of the specified document
        void reset(const xml_document& proto)

        # Load document from zero-terminated string. No encoding conversions are applied.
        xml_parse_result load_string(const char_t* contents)
        xml_parse_result load_string(const char_t* contents, unsigned int options)

        # Load document from buffer. Copies/converts the buffer, so it may be deleted or changed after the function returns.
        xml_parse_result load_buffer(const void* contents, size_t size)
        xml_parse_result load_buffer(const void* contents, size_t size, unsigned int options, xml_encoding encoding)

        # Load document from buffer, using the buffer for in-place parsing (the buffer is modified and used for storage of document data).
        # You should ensure that buffer data will persist throughout the document's lifetime, and free the buffer memory manually once document is destroyed.
        xml_parse_result load_buffer_inplace(void* contents, size_t size)
        xml_parse_result load_buffer_inplace(void* contents, size_t size, unsigned int options, xml_encoding encoding)

        # Load document from buffer, using the buffer for in-place parsing (the buffer is modified and used for storage of document data).
        # You should allocate the buffer with pugixml allocation function; document will free the buffer when it is no longer needed (you can't use it anymore).
        xml_parse_result load_buffer_inplace_own(void* contents, size_t size)
        xml_parse_result load_buffer_inplace_own(void* contents, size_t size, unsigned int options, xml_encoding encoding)

        # Save XML document to writer (semantics is slightly different from xml_node::print, see documentation for details).
        void save(xml_writer& writer)

        # # Save XML document to stream (semantics is slightly different from xml_node::print, see documentation for details).
        # void save(ostream_t& stream)

        # Get the document element (root node)
        xml_node document_element()
