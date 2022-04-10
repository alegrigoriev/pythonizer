
def _get_element(base, index):
    """Safe element getter from a list, tuple, or Array - returns None if the element doesn't exist"""
    if index in base:
        return base[index]
    return None
