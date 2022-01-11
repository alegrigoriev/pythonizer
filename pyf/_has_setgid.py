
def _has_setgid(path):        # -g
    if not path:
        return False
    if hasattr(path, 'mode'):
        return (path.mode & stat.S_ISGID) != 0
    return (os.stat(path).st_mode & stat.S_ISGID) != 0
