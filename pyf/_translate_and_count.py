
def _translate_and_count(table, var, replace=True, complement=False, delete=False, squash=False):
    """Perform a tr translate, but also count the # of matches"""
    result = []
    ctr = 0;
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
    if not replace:
        return (var, ''.join(result))
    return (''.join(result), ctr)
