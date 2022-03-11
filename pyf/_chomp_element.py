
def _chomp_element(base, index, value):
    """Implementation of perl = and chomp on an array element"""
    if value is None:
        value = ''
    base[index] = value.rstrip("\n")
    return len(value) - len(base[index])
