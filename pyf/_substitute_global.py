
def _substitute_global(packname, varname, this, that, replace=True, count=0):
    """Perform a re substitute on a global, and also count the # of matches"""
    namespace = getattr(builtins, packname)
    var = _str(getattr(namespace, varname))
    (result, ctr) = re.subn(this, that, var, count=count)
    if replace:
        setattr(namespace, varname, result)
        return ctr
    return result
