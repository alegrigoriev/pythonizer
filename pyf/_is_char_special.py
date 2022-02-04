
def _is_char_special(path):        # -c
    if not path:
        return False
    if hasattr(path, '_mode'):
        return stat.S_ISCHR(path._mode)
    return stat.S_ISCHR(os.stat(path).st_mode)
