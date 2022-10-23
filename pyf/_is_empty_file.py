
def _is_empty_file(path):        # -z
    if not path:
        return None
    if hasattr(path, '_size'):
        return 1 if path._size == 0 else ''
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return 1 if not os.path.getsize(path) else ''
