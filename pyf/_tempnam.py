
def _tempnam(template, suffix):
    """Implementation of File::Temp::tempnam()"""
    template = template.replace('X', '')
    (base, dirn, tail) = _fileparse(template)
    (fh, name) = tempfile.mkstemp(prefix=base, dir=dirn, suffix=suffix)
    fh.close()
    return name
