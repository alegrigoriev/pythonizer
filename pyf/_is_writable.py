
def _is_writable(path):     # -w
    if not path:
        return False
    if hasattr(path, 'cando'):
        return path.cando(stat.S_IWUSR, 1)
    return os.access(path, os.W_OK, effective_ids=(os.access in os.supports_effective_ids))
