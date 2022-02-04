
def _is_socket(path):        # -S
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISSOCK(path._mode)
    return stat.S_ISSOCK(os.stat(path).st_mode)
