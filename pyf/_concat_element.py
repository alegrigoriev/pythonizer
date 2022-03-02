
def _concat_element(base, index, value):
    """Implementation of perl .= on an array element"""
    try:
        base[index] += value
    except TypeError:
        if value is None:
            if base[index] is None:
                base[index] = ''
            else:
                base[index] = str(base[index])
        else:
            if base[index] is None:
                base[index] = str(value)
            else:
                base[index] = str(base[index]) + str(value)
    return base[index]
