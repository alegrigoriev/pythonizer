
def _is_owned(path):        # -o
    if not path:
        return False
    if hasattr(path, 'uid'):
        return path.uid == os.geteuid()
    return os.stat(path).st_uid == os.geteuid()
