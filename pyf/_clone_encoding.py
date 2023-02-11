
def _clone_encoding(encoding):
    """Implementation of Encoding::clone_encoding"""
    obj = _find_encoding(encoding)
    if obj is None:
        return obj
    return copy.deepcopy(obj)
