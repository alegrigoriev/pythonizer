
def _is_real_readable(path):        # -R
    if not path:
        return False
    if hasattr(path, 'cando'):
        return path.cando(stat.S_IRUSR, 0)
    return os.access(path, os.R_OK)
