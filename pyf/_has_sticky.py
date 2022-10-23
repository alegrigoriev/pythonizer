
def _has_sticky(path):        # -k
    if not path:
        return ''       # False
    if hasattr(path, '_mode'):
        return 1 if (path._mode & stat.S_ISVTX) != 0 else ''
    return 1 if (os.stat(path).st_mode & stat.S_ISVTX) != 0 else ''
