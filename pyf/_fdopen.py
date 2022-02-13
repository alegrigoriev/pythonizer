
def _fdopen(fh, fd, mode):
    """Implementation of $fh->fdopen(fd, mode)"""
    if isinstance(fd, str) and re.match(r'^\d+$', fd):
        fd = int(fd)
    if isinstance(fd, int):
        fd = f'={fd}'
    if fh and not fh.closed:
        fh.close()
    return _create_all_fh_methods(_open_dynamic(_open_mode_string(mode) + '&' + fd))
