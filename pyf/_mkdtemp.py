
def _mkdtemp(template):
    """Implementation of File::Temp::mkdtemp()"""
    template = template.replace('X', '')
    (base, dirn, tail) = _fileparse(template)
    return tempfile.mkdtemp(prefix=base, dir=dirn)
