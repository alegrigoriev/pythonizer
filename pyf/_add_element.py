
def _add_element(base, index, value):
    """Implementation of += on an array element"""
    try:
        base[index] += value
    except TypeError:
        if isinstance(value, int) or isinstance(value, float):
            base[index] = _num(base[index]) + value
        elif value is None:
            base[index] = _num(base[index])
        else:
            base[index] = _num(base[index]) + _num(value)
    return base[index]
