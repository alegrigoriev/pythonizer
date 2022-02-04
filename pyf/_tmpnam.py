
def _tmpnam():
    """Implementation of POSIX tmpnam() in list context"""
    ntf = tempfile.NamedTemporaryFile(delete=False)
    return (ntf, ntf.name)
