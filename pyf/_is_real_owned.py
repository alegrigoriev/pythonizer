
def _is_real_owned(path):   # -O
    if not path:
        return False
    if hasattr(path, '_uid'):
        return path._uid == os.getuid()
    return os.stat(path).st_uid == os.getuid()
