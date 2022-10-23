
def _is_real_writable(path):
    if hasattr(path, 'cando'):
        return 1 if path.cando(stat.S_IRUSR, 0) else ''
    if hasattr(path, 'fileno') and os.access in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return 1 if os.access(path, os.W_OK) else ''
