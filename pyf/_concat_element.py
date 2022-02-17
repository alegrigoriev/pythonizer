
def _concat_element(base, index, value):
    """Implementation of perl .= on an array element"""
    base[index] += value
    return base[index]
