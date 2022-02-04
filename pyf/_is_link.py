
def _is_link(path):        # -l
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISLNK(path._mode)
    return os.path.islink(path)
