
def _is_readable(path):     # -r
    if not path:
        return False
    if hasattr(path, 'cando'):
        return path.cando(stat.S_IRUSR, 1)
    if hasattr(path, 'fileno') and os.access in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return os.access(path, os.R_OK, effective_ids=(os.access in os.supports_effective_ids))
