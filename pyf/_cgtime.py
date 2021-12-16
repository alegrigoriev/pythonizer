
def _cgtime(secs=None):
    """Replacement for perl built-in gmtime function in scalar context"""
    return tm_py.asctime(tm_py.gmtime(secs))

