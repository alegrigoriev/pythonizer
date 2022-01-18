
def _translate_and_count(table, var, replace=True, complement=False, delete=False):
    """Perform a tr translate, but also count the # of matches"""
    result = []
    ctr = 0;
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
    if not replace:
        return (var, ''.join(result))
    return (''.join(result), ctr)
