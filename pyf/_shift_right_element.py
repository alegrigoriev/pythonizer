
def _shift_right_element(base, index, value):
    base[index] >>= value
    return base[index]
