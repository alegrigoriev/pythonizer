
def _substitute_global(packname, varname, this, that, replace=True, count=0):
    """Perform a re substitute on a global, and also count the # of matches"""
    ctr = 0;
    def _match(_m):
        nonlocal ctr
        ctr += 1
        return that

    namespace = getattr(builtins, packname)
    var = getattr(namespace, varname)
    result = re.sub(this, _match, var, count=count)
    if replace:
        setattr(namespace, varname, result)
        return ctr
    return result
