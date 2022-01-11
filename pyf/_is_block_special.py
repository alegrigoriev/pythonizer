
def _is_block_special(path):        # -b
    if not path:
        return False
    if hasattr(path, 'mode'):
        return stat.S_ISBLK(path.mode)
    return stat.S_ISBLK(os.stat(path).st_mode)
