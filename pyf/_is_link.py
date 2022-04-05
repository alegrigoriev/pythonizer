
def _is_link(path):        # -l
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISLNK(path._mode)
    if hasattr(path, 'fileno') and os.lstat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return os.path.islink(path)
