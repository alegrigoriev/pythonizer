
def _get_element(base, index):
    """Safe element getter from a list, tuple, or Array - returns None if the element doesn't exist"""
    if index < 0:
        index += len(base)
    if index >= 0 and index < len(base):
        return base[index]
    return None
