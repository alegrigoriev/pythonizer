
def _is_readable(path):     # -r
    if not path:
        return ''       # False
    if hasattr(path, 'cando'):
        return 1 if path.cando(stat.S_IRUSR, 1) else ''
    if hasattr(path, 'fileno') and os.access in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return 1 if os.access(path, os.R_OK, effective_ids=(os.access in os.supports_effective_ids)) else ''
