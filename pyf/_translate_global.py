
def _translate_global(packname, varname, table, replace=True, complement=False):
    """Perform a tr translate on a global, and also count the # of matches"""
    result = []
    ctr = 0;
    namespace = getattr(builtins, packname)
    var = getattr(namespace, varname)
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
        setattr(namespace, varname, ''.join(result))
        return ctr
    return ''.join(result)
