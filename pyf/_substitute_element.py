
def _substitute_element(base, index, this, that, count=0, replace=True):
    """Perform a re substitution on an array element or hash value, and also count the # of matches"""
    (result, ctr) = re.subn(this, that, base[index], count=count)
    if replace:
        base[index] = result
        return ctr
    return result
