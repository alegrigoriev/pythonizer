
def _substitute_element(base, index, this, that, count=0, replace=True):
    """Perform a re substitution on an array element or hash value, and also count the # of matches"""
    ctr = 0;
    def _match(_m):
        nonlocal ctr
        ctr += 1
        return that

    result = re.sub(this, _match, base[index], count=count)
    if replace:
        base[index] = result
        return ctr
    return result
