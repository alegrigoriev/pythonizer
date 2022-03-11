
def _chomp_global(packname, varname, value):
    """Assigns a value to a package global variable, does a chomp and returns the number of chars chopped"""
    namespace = getattr(builtins, packname)
    if value is None:
        value = ''
    chomped_value = value.rstrip("\n")
    setattr(namespace, varname, chomped_value)
    return len(value) - len(chomped_value)
