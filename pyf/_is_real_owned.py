
def _is_real_owned(path):   # -O
    if not path:
        return False
    if hasattr(path, '_uid'):
        return path._uid == os.getuid()
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return os.stat(path).st_uid == os.getuid()
