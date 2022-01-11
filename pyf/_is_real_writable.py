
def _is_real_writable(path):
    if hasattr(path, 'cando'):
        return path.cando(stat.S_IRUSR, 0)
    return os.access(path, os.W_OK)
