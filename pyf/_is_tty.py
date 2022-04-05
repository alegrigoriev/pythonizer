
def _is_tty(path):        # -t
    if not path:
        return False
    if hasattr(path, 'isatty'):
        return path.isatty()
    if isinstance(path, tuple):
        raise ValueError('-t not supported on File_stat')
    if hasattr(path, 'name'):
        path = path.name
    try:
        with open(path, 'r') as t:
            return t.isatty()
    except Exception:
        return False
