
def _translate_element(base, index, table, replace=True, complement=False, delete=False, squash=False):
    """Perform a tr translate on a global, and also count the # of matches"""
    result = []
    ctr = 0;
    var = base[index]
    pv = None
    for ch in var:
        if ord(ch) > 256 and complement:
            ch = chr(256)
        try:
            v = table[ord(ch)]
            ctr += 1
        except LookupError:
            v = ch
            pv = None
        if v is not None:
            if isinstance(v, int):
                v = chr(v)
            if pv != v or not squash:
                result.append(v)
        pv = v
    if replace:
        base[index] = ''.join(result)
        return ctr
    return ''.join(result)
