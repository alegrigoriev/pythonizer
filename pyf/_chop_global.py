
def _chop_global(packname, varname, value):
    """Assigns a value to a package global variable, does a chop and returns the value chopped"""
    namespace = getattr(builtins, packname)
    if value is None:
        value = ''
    result = value[-1:]
    setattr(namespace, varname, value[0:-1])
    return result
