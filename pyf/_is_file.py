
def _is_file(path):        # -f
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISREG(path._mode)
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return os.path.isfile(path)
