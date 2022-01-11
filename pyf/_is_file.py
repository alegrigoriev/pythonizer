
def _is_file(path):        # -f
    if not path:
        return False
    if hasattr(path, 'mode'):
        return stat.S_ISREG(path.mode)
    return os.path.isfile(path)
