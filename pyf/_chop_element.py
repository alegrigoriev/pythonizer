
def _chop_element(base, index, value):
    """Implementation of perl = and chop on an array element"""
    if value is None:
        value = ''
    result = value[-1:]
    base[index] = value[0:-1]
    return result
