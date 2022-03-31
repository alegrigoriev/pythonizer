
def _translate_global(packname, varname, table, replace=True, complement=False, delete=False, squash=False):
    """Perform a tr translate on a global, and also count the # of matches"""
    result = []
    ctr = 0;
    pv = None
    namespace = getattr(builtins, packname)
    var = _str(getattr(namespace, varname))
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
        setattr(namespace, varname, ''.join(result))
        return ctr
    return ''.join(result)
