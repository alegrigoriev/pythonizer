
def perl_open(file,mode,encoding=None):
    """Replacement for perl built-in open function when used in an expression.
       FIXME: Handle pipe I/O via subprocess"""
    try:
        return open(file,mode,encoding)
    except Exception:
        return None    # sys.last_value will be set

