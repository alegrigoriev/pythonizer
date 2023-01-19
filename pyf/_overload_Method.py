
def _overload_Method(obj, op):
    """Given an object and an operation string, return a reference to
    the code if it's overloaded, else return None"""
    key = f"({op}"
    if hasattr(obj, key):
        return getattr(obj, key)
    return None
