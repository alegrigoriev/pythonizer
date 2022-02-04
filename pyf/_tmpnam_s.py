
def _tmpnam_s():
    """Implementation of POSIX tmpnam() in scalar context"""
    ntf = tempfile.NamedTemporaryFile(delete=False)
    result = ntf.name
    ntf.close()
    return result
