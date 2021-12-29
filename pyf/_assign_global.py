
def _assign_global(varname, value):
    """Assigns a value to a package global variable and returns the value"""
    namespace = getattr(builtins, __PACKAGE__)
    setattr(namespace, varname, value)
    return value
