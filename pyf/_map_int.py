
def _map_int(*args):
    """Convert each element to an int"""
    return list(map(_int, _flatten(args)))
