
def _map_num(*args):
    """Convert each element to a num"""
    return list(map(_num, _flatten(args)))
