
def _is_pipe(path):        # -p
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISFIFO(path._mode)
    return stat.S_ISFIFO(os.stat(path).st_mode)
