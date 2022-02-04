
def _mkstemps(template, suffix):
    """Implementation of File::Temp::mkstemps()"""
    template = template.replace('X', '')
    (base, dirn, tail) = _fileparse(template)
    fh = tempfile.NamedTemporaryFile(prefix=base, dir=dirn, suffix=suffix, delete=False)
    return(fh, fh.name)
