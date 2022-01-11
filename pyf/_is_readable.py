
def _is_readable(path):     # -r
    if not path:
        return False
    if hasattr(path, 'cando'):
        return path.cando(stat.S_IRUSR, 1)
    return os.access(path, os.R_OK, effective_ids=True)
