
def _perl_open(file,mode,encoding=None):
    """Replacement for perl built-in open function when used in an expression.
       FIXME: Handle pipe I/O via subprocess"""
    global OS_ERROR
    try:
        return open(file,mode,encoding=encoding)
    except Exception as _e:
        OS_ERROR = str(_e)
        return None

