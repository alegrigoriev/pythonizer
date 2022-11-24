
def _chomp_global(packname, varname, value):
    """Assigns a value to a package global variable, does a chomp and returns the number of chars chopped"""
    namespace = getattr(builtins, packname)
    if value is None:
        value = ''
    if INPUT_RECORD_SEPARATOR is None or isinstance(INPUT_RECORD_SEPARATOR, int):
        setattr(namespace, varname, value)
        return 0

    if INPUT_RECORD_SEPARATOR == '':
        chomped_value = value.rstrip("\n")
    else:
        chomped_value = value.rstrip(INPUT_RECORD_SEPARATOR)
    setattr(namespace, varname, chomped_value)
    return len(value) - len(chomped_value)
