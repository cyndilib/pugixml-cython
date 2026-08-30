from Cython.Build import cythonize
from Cython.Compiler import Options
from setuptools import Extension, setup

Options.fast_fail = True

extensions = [
    Extension(
        "pugixml_cython.pugixml",
        sources=[
            "src/pugixml_cython/pugixml.pyx",
        ],
        language="c++"
    )
]

setup(
    name="pugixml_cython",
    ext_modules=cythonize(extensions)
)
