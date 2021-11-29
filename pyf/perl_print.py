
def perl_print(*args, **kwargs):
    """Replacement for perl built-in print function when used in an expression,
    where it must return True if successful"""
    try:
        print(*args, **kwargs)
        return True
    except Exception:
        return False

