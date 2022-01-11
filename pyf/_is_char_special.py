
def _is_char_special(path):        # -c
    if not path:
        return False
    if hasattr(path, 'mode'):
        return stat.S_ISCHR(path.mode)
    return stat.S_ISCHR(os.stat(path).st_mode)
