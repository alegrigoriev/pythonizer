
def _is_socket(path):        # -S
    if not path:
        return False
    if hasattr(path, 'mode'):
        return stat.S_ISSOCK(path.mode)
    return stat.S_ISSOCK(os.stat(path).st_mode)
