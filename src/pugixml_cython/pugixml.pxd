# cython: language_level=3
# distutils: language = c++
# distutils: include_dirs = src/pugixml_cython/extern/pugixml/src

from libc.stdint cimport *
from libc.stddef cimport *
from libcpp.memory cimport unique_ptr
from libcpp.string cimport string as cpp_string
from libcpp.map cimport map as cpp_map
from libcpp.pair cimport pair as cpp_pair
# from libcpp.list cimport list as cpp_list
from libcpp.vector cimport vector
# from libcpp.array cimport array as cpp_array
from libcpp.set cimport set as cpp_set


include "pugiwrapper.pxi"

# cdef extern from * nogil:
#     """
#     #include <cstdlib>
#     struct NodeStructDeleter {
#         void operator()(NodeStruct* node_struct) const
#         {
#             if (node_struct != NULL)
#             {
#                 free(node_struct);
#             }
#         }
#     }
#     """
#     cdef struct NodeStructDeleter: pass

ctypedef cpp_map[cpp_string, cpp_string] cpp_string_map
ctypedef cpp_pair[cpp_string, cpp_string] cpp_string_pair
ctypedef vector[xml_node*] cpp_xml_node_list
ctypedef cpp_map[string_t, xml_node*] cpp_string_node_ptr_map
ctypedef cpp_pair[string_t, xml_node*] cpp_string_node_ptr_pair
ctypedef cpp_map[cpp_string, vector[NodeStruct*]] children_by_name_map



# This seems excessive, but since NodeStruct uses C++ vectors and maps,
# it's way easier to wrap it as a C++ class for allocation purposes.
cdef extern from * namespace "pugiwrapper" nogil:
    """
    #include <cstdlib>
    #include <vector>
    #include <array>
    #include <map>
    #include <string>
    #include <algorithm>
    #include <utility>
    #include <pugixml.hpp>

    namespace pugiwrapper {
        class NodeStruct {
            public:
                pugi::xml_node_type type;
                std::string name;
                std::string path;
                std::map<std::string, std::string> attribute_map;
                // std::vector<NodeStruct*> children;
                const char* text;
                // NodeStruct* parent;
                bool is_empty;
                bool has_text;
                size_t nest_level;
                size_t hash_value;

                NodeStruct() : type(pugi::node_null), /*parent(NULL),*/ is_empty(false), has_text(false), hash_value(0) {}
                ~NodeStruct() {
                    type = pugi::node_null;
                    //parent = NULL;
                    text = NULL;
                    is_empty = false;
                    has_text = false;
                    hash_value = 0;
                }
        };
    }

    """
    cdef cppclass NodeStruct:
        #NodeStruct* parent
        xml_node_type type
        cpp_string name
        cpp_string path
        cpp_string_map attribute_map
        bint is_empty
        bint has_text
        size_t nest_level
        size_t hash_value
        const char_t* text
        #NodeStruct* parent
        # vector[NodeStruct*] children



cdef struct NodePosition:
    size_t index
    size_t nest_level
    NodePosition* parent




cpdef enum NodeType:
    NODE_NULL = xml_node_type.node_null
    NODE_ELEMENT = xml_node_type.node_element
    NODE_PCData = xml_node_type.node_pcdata
    NODE_CDATA = xml_node_type.node_cdata
    NODE_COMMENT = xml_node_type.node_comment
    NODE_PI = xml_node_type.node_pi
    NODE_DECLARATION = xml_node_type.node_declaration
    NODE_DOCTYPE = xml_node_type.node_doctype

cdef inline xml_node_type node_type_cast(NodeType node_type) noexcept nogil:
    return <xml_node_type>node_type

cdef inline NodeType node_type_uncast(xml_node_type node_type) noexcept nogil:
    return <NodeType>node_type


# cdef struct NodeTreeInfoStruct:
#     NodeStruct* root
#     children_by_name_map children_by_name
#     cpp_map[cpp_string, vector[NodeStruct*]] children_by_path
#     cpp_map[size_t, NodeStruct*] children_by_hash



# ctypedef vector[NodePositionBase] node_position_vector
ctypedef cpp_set[xml_node_type] xml_node_type_set

cdef dict _attribute_map_to_dict(cpp_string_map& attribute_map)

cdef class Document:
    cdef xml_document doc
    cdef Element _root_element
    cdef bint _has_document
    cdef dict _nodes_by_hash_value
    cdef xml_node_type_set _excluded_node_types

    cdef int _reset(self) except -1 nogil
    cdef int _load_string(self, const char_t* xml_string) except -1 nogil
    cdef bint _has_root(self) except -1 nogil
    cdef Element _get_root(self)
    cdef int _collect_nodes_by_hash_value(self) except -1
    cdef Element _find_from_hash_value(self, size_t hash_value)
    cdef int _xpath_find(self, const char_t* xpath, NodeStruct* node_struct) except -1 nogil
    # cdef list _xpath_findall(self, const char_t* xpath)
    cdef int _xpath_findall(self, const char_t* xpath, vector[NodeStruct*]* results) except -1 nogil



cdef class Element:
    cdef NodeStruct node_struct
    cdef NodePosition _position
    cdef vector[size_t] _position_indices
    cdef Element _parent
    cdef list _children
    cdef size_t _children_count

    @staticmethod
    cdef Element _create(
        xml_node* node,
        xml_node_type_set* excluded_node_types,
        Element parent = *
    )
    cdef int _initialize_node_struct(
        self,
        xml_node* node,
        xml_node_type_set* excluded_node_types,
        Element parent = *
    ) except -1
    cdef int _build_children(
        self,
        xml_node* node,
        xml_node_type_set* excluded_node_types
    ) except -1
    cdef int _clear(self) except -1 nogil
    cdef Element _get_root(self)
    cdef NodeType _get_type(self) noexcept nogil
    cdef bint _is_null(self) noexcept nogil
    # cdef Element _find_from_hash_value(self, size_t hash_value)
