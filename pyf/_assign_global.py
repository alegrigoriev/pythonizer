
def _assign_global(packname, varname, value):
    """Assigns a value to a package global variable and returns the value"""
    namespace = getattr(builtins, packname)
    setattr(namespace, varname, value)
    return value
