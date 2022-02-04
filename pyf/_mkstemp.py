
def _mkstemp(template):
    """Implementation of File::Temp::mkstemp()"""
    template = template.replace('X', '')
    (base, dirn, tail) = _fileparse(template)
    fh = tempfile.NamedTemporaryFile(prefix=base, dir=dirn, delete=False)
    return (fh, fh.name)
