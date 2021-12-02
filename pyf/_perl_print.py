
def _perl_print(*args, **kwargs):
    """Replacement for perl built-in print function when used in an expression,
    where it must return True if successful"""
    global OS_ERROR
    try:
        print(*args, **kwargs)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        return False

