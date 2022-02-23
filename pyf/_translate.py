
def _translate(table, var, replace=True, complement=False, delete=False, squash=False):
    """Perform a tr translate operation"""
    result = []
    pv = None
    for ch in var:
        if ord(ch) > 256 and complement:
            ch = chr(256)
        try:
            v = table[ord(ch)]
        except LookupError:
            v = ch
            pv = None
        if v is not None:
            if isinstance(v, int):
                v = chr(v)
            if pv != v or not squash:
                result.append(v)
        pv = v
    return ''.join(result)
