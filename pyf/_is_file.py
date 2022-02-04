
def _is_file(path):        # -f
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISREG(path._mode)
    return os.path.isfile(path)
