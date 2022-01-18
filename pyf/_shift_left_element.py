
def _shift_left_element(base, index, value):
    base[index] <<= value
    return base[index]
