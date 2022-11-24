
def _chomp_element(base, index, value):
    """Implementation of perl = and chomp on an array element"""
    if value is None:
        value = ''
    if INPUT_RECORD_SEPARATOR is None or isinstance(INPUT_RECORD_SEPARATOR, int):
        base[index] = value
        return 0

    if INPUT_RECORD_SEPARATOR == '':
        chomped_value = value.rstrip("\n")
    else:
        chomped_value = value.rstrip(INPUT_RECORD_SEPARATOR)

    base[index] = chomped_value
    return len(value) - len(base[index])
