
def _has_setuid(path):        # -u
    if not path:
        return False
    if hasattr(path, 'mode'):
        return (path.mode & stat.S_ISUID) != 0
    return (os.stat(path).st_mode & stat.S_ISUID) != 0
