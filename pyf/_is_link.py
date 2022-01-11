
def _is_link(path):        # -l
    if not path:
        return False
    if hasattr(path, 'mode'):
        return stat.S_ISLNK(path.mode)
    return os.path.islink(path)
