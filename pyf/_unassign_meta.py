
def _unassign_meta(packname, varname):
    """Unassigns a variable in the metaclass of a package global variable.
    This is use for untie $scalar"""
    namespace = getattr(builtins, packname)
    if not isinstance(namespace, type):
        return
    meta = namespace.__class__
    try:
        delattr(meta, varname)
    except AttributeError:
        pass
