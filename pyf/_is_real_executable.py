
def _is_real_executable(path):      # -X
    if not path:
        return False
    if hasattr(path, 'cando'):
        return path.cando(stat.S_IXUSR, 0)
    return os.access(path, os.X_OK)
