
def _perl_print(*args, **kwargs):
    """Replacement for perl built-in print function when used in an expression,
    where it must return True if successful"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if 'file' in kwargs and kwargs['file'] is None:
            raise Die('print() on unopened filehandle')
        print(*args, **kwargs)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"print failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return False

