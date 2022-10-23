
def _has_setuid(path):        # -u
    if not path:
        return ''       # False
    if hasattr(path, '_mode'):
        return 1 if (path._mode & stat.S_ISUID) != 0 else ''
    return 1 if (os.stat(path).st_mode & stat.S_ISUID) != 0 else ''
