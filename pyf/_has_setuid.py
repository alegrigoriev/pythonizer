
def _has_setuid(path):        # -u
    if not path:
        return False
    if hasattr(path, '_mode'):
        return (path._mode & stat.S_ISUID) != 0
    return (os.stat(path).st_mode & stat.S_ISUID) != 0
