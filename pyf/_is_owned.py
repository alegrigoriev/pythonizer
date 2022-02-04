
def _is_owned(path):        # -o
    if not path:
        return False
    if hasattr(path, '_uid'):
        return path._uid == os.geteuid()
    return os.stat(path).st_uid == os.geteuid()
