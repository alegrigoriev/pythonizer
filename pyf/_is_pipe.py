
def _is_pipe(path):        # -p
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISFIFO(path._mode)
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return stat.S_ISFIFO(os.stat(path).st_mode)
