
def _is_char_special(path):        # -c
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISCHR(path._mode)
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return stat.S_ISCHR(os.stat(path).st_mode)
