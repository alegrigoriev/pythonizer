
def _assign_meta(packname, varname, value):
    """Assigns a value in the metaclass of a package global variable and returns the value.  Creates the metaclass if
    need be.  This is use for tie $scalar"""
    namespace = getattr(builtins, packname)
    if not isinstance(namespace, type):
        _init_package(packname, is_class=True, autovivification=namespace.__autovivification__)
        namespace = getattr(builtins, packname)
    meta = namespace.__class__
    setattr(meta, varname, value)
    return value
