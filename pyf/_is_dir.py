
def _is_dir(path):        # -d
    if not path:
        return ''       # False
    if hasattr(path, '_mode'):
        return 1 if stat.S_ISDIR(path._mode) else ''
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return 1 if os.path.isdir(path) else ''
