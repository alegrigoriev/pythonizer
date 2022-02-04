
def _mktemp(template):
    """Implementation of File::Temp::mktemp()"""
    template = template.replace('X', '')
    (base, dirn, tail) = _fileparse(template)
    ntf = tempfile.NamedTemporaryFile(prefix=base, dir=dirn, delete=False)
    result = ntf.name
    ntf.close()
    return result
