
def _map_str(*args):
    """Convert each element to a str"""
    return list(map(_str, _flatten(args)))
