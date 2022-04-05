
def _is_owned(path):        # -o
    if not path:
        return False
    if hasattr(path, '_uid'):
        return path._uid == os.geteuid()
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return os.stat(path).st_uid == os.geteuid()
