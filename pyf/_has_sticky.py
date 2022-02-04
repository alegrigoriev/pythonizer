
def _has_sticky(path):        # -k
    if not path:
        return False
    if hasattr(path, '_mode'):
        return (path._mode & stat.S_ISVTX) != 0
    return (os.stat(path).st_mode & stat.S_ISVTX) != 0
