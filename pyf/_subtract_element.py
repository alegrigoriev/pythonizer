
def _subtract_element(base, index, value):
    """Implementation of -= on an array element"""
    try:
        base[index] -= value
    except TypeError:
        if isinstance(value, int) or isinstance(value, float):
            base[index] = _num(base[index]) - value
        elif value is not None:
            raise
    return base[index]
