# pugixml-cython

A Cython wrapper for [pugixml] designed for use by other Cython projects.

[pugixml] is a light-weight, simple and fast XML parser for C++ with XPath support.

## Why does this exist?

There are several excellent Python wrappers for [pugixml], including some implemented using Cython. This project isn't intended to compete with them as a general-purpose Python XML library.

Its primary purpose is to provide pugixml's functionality as a native [Cython] library, including its Cython `.pxd` [declaration files](https://cython.readthedocs.io/en/latest/src/userguide/sharing_declarations.html), so that other Cython projects can `cimport` and use it directly.


Beyond that, it provides significant performance gains over Python's standard-library XML parsers, but this project makes no claims of being the most performant.


## Installation

You can install the pre-built wheels from PyPI (once available) using:


If you're using [uv] (and if you aren't, stop reading this and go read the documentation 😎):

```console
uv add pugixml-cython
```

Or, for plain PIP users:

```console
pip install pugixml-cython
```


## Features


This project is primarily focused on XML parsing. The exposed XML DOM is currently read-only; node/attribute mutation and serialization are not yet implemented.


### Implemented

- Native Cython wrapper for pugixml allowing `cimport` of the declarations
- XML parsing from strings
- XPath support
- Cross-platform support
  - [cibuildwheel] is used to build wheels for:
    - Windows x86/x64
    - macOS (arm64)
    - manylinux (x86_64 and aarch64)
    - musllinux (x86_64 and aarch64)
- Node traversal
- Attribute access
- Text content access

### Planned / Not Yet Implemented

- Serialization support
- DOM manipulation support
- Attribute manipulation support


## Dependencies

For the most part, the runtime dependencies are almost zero.
Pre-built wheels bundle pugixml, so users do not need to install pugixml or a C++ toolchain separately.

> [!NOTE]
> There is one runtime dependency.
> For Python 3.10, [typing-extensions] is required and will be installed automatically if not already present (but why would you be using such an old version of Python?)


## Project Links

Source Code
: https://github.com/cyndilib/pugixml-cython


PyPI
: https://pypi.org/project/pugixml-cython/



## Cython Usage


```cython
from libcpp.map cimport map as cpp_map
from libcpp.string cimport string as cpp_string
from pugixml_cython cimport Document, Element, NodeType

# Example XML string
cdef const char* xml_string = b'<root id="root_id"><child>content</child></root>'


cdef Document doc = Document()
doc._load_string(xml_string)

cdef Element root = doc._root()

# Children can be accessed through `Element._children`.
# It's a list of `Element` objects, so there will be some Python overhead:
cdef Element child = root._children[0]

# Much of the underlying element data is exposed through
# the Element.node_struct structure.
#
# Attributes are exposed as a cpp_map[cpp_string, cpp_string]:
attr_value = root.node_struct.attribute_map[cpp_string("id")]
child_text = child.node_struct.text

```

### Cython Compilation


When compiling a downstream Cython extension, the pugixml header files need to be available to the C++ compiler. pugixml-cython provides a helper for locating them, similar to `numpy.get_include()`:

```python
from pugixml_cython import get_include_dirs
include_path: list["Path"] = get_include_dirs()
```


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

`pugixml` is included as source code and is separately licensed under the MIT License.  See the [pugixml LICENSE](LICENSE-pugixml) file for details.



[pugixml]: https://github.com/zeux/pugixml
[Cython]: https://cython.readthedocs.io/en/latest/index.html
[cibuildwheel]: https://cibuildwheel.pypa.io/en/stable/
[typing-extensions]: https://pypi.org/project/typing-extensions/
[uv]: https://docs.astral.sh/uv/
