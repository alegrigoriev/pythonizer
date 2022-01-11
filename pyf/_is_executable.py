
def _is_executable(path):       # -x
    if not path:
        return False
    if hasattr(path, 'cando'):
        return path.cando(stat.S_IXUSR, 1)
    return os.access(path, os.X_OK, effective_ids=True)
