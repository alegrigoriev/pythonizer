
def _init_global(varname, value):
    """Return the proper value to initialize a package global variable only once"""
    namespace = getattr(builtins, __PACKAGE__)
    if hasattr(namespace, varname):
        return getattr(namespace, varname)
    setattr(namespace, varname, value)
    return value
