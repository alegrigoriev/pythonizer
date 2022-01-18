
def _translate_element(base, index, table, replace=True, complement=False):
    """Perform a tr translate on a global, and also count the # of matches"""
    result = []
    ctr = 0;
    var = base[index]
    for ch in var:
        try:
            v = table[ord(ch)]
            ctr += 1
        except LookupError:
            v = ch
        if v is not None:
            if isinstance(v, int):
                v = chr(v)
            result.append(v)

    if replace:
        base[index] = ''.join(result)
        return ctr
    return ''.join(result)
