
def _set_element(base, index, value):
    """Implementation of perl = on an array element or hash key"""
    base[index] = value
    return value
