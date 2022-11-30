
def _fetch_perl_global(perlname):
    """Fetch the value of a package global variable specified by it's perl name"""
    (packname, varname) = perlname.rsplit('::', maxsplit=1)
    packname = packname.replace('::', '.')
    if packname == '':
        packname = 'main'
    if not hasattr(builtins, packname):
        _init_package(packname)
    namespace = getattr(builtins, packname)
    if varname in _PYTHONIZER_KEYWORDS:
        varname += '_'
    if hasattr(namespace, varname):
        return getattr(namespace, varname)
    if varname == '' or varname == '_h':   # They want the namespace dictionary
        return namespace.__dict__
    return None
