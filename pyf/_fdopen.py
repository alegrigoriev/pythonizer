
def _fdopen(fh, fd, mode):
    """Implementation of $fh->fdopen(fd, mode)"""
    if isinstance(fd, str) and re.match(r'^\d+$', fd):
        fd = int(fd)
    if isinstance(fd, int):
        fd = f'={fd}'
    return _open_dynamic(_open_mode_string(mode) + '&' + fd)
