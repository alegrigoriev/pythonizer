
def _is_dir(path):        # -d
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISDIR(path._mode)
    return os.path.isdir(path)
