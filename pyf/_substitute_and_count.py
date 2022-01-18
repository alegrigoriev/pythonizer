
def _substitute_and_count(this, that, var, replace=True, count=0):
    """Perform a re substitute, but also count the # of matches"""
    ctr = 0;
    def _match(_m):
        nonlocal ctr
        ctr += 1
        return that

    result = re.sub(this, _match, var, count=count)
    if not replace:
        return (var, result)
    return (result, ctr)
