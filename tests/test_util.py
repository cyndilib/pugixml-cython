from pathlib import Path

from pugixml_cython import get_include_dirs


def test_get_include_dirs() -> None:
    """Test that all include directories returned by get_include_dirs contain
    at least one header file.
    """
    def has_header_file(path: Path) -> bool:
        for ext in ("h", "hpp"):
            if any(path.glob(f"*.{ext}")):
                return True
        return False
    include_dirs = get_include_dirs()
    for include_dir in include_dirs:
        assert has_header_file(include_dir)
