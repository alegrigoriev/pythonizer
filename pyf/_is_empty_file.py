
def _is_empty_file(path):        # -z
    if not path:
        return None
    if hasattr(path, '_size'):
        return path._size == 0
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return not os.path.getsize(path)
