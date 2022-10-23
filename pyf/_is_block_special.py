
def _is_block_special(path):        # -b
    if not path:
        return ''       # False
    if hasattr(path, '_mode'):
        return 1 if stat.S_ISBLK(path._mode) else ''
    if hasattr(path, 'fileno') and os.stat in os.supports_fd:
        path = path.fileno()
    elif hasattr(path, 'name'):
        path = path.name
    return 1 if stat.S_ISBLK(os.stat(path).st_mode) else ''
