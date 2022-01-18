
def _init_global(packname, varname, value):
    """Return the proper value to initialize a package global variable only once"""
    namespace = getattr(builtins, packname)
    if hasattr(namespace, varname):
        return getattr(namespace, varname)
    setattr(namespace, varname, value)
    return value
