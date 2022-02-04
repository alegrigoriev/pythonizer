
def _has_setgid(path):        # -g
    if not path:
        return False
    if hasattr(path, '_mode'):
        return (path._mode & stat.S_ISGID) != 0
    return (os.stat(path).st_mode & stat.S_ISGID) != 0
