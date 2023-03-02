
def _store_perl_meta(perlname, value, infer_suffix=False):
    """Assigns a value to a package meta variable specified by it's perl name
    and returns the value.  Optional keyword argument infer_suffix
    will map the variable's suffix based on the type of the value,
    e.g. it will add _h for a hash.  This is used for tie ${"${pkg}::$scalarname"}"""
    (packname, varname) = perlname.rsplit('::', maxsplit=1)
    packname = packname.replace('::', '.')
    if packname == '':
        packname = 'main'
    if infer_suffix:
        if isinstance(value, (str, float, int, bytes)):
            varname += '_v'
        elif hasattr(value, 'isHash'):
            if value.isHash:
                varname += '_h'
            else:
                varname += '_a'
        elif isinstance(value, collections.abc.Mapping):
            varname += '_h'
        elif isinstance(value, collections.abc.Iterable):
            varname += '_a'
    _assign_meta(packname, varname, value)
    if varname in _PYTHONIZER_KEYWORDS:
        varname += '_'
        _assign_meta(packname, varname, value)
    return value
