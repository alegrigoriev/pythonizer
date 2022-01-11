
def _is_dir(path):        # -d
    if not path:
        return False
    if hasattr(path, 'mode'):
        return stat.S_ISDIR(path.mode)
    return os.path.isdir(path)
