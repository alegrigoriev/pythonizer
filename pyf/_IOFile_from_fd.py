
def _IOFile_from_fd(fd, mode):
    """Implementation of IO::File::new_from_fd()"""
    global TRACEBACK, AUTODIE
    try:
        return _fdopen(None, fd, mode)
    except Exception as e:
        if TRACEBACK:
            _cluck(f"IO::File::new_from_fd({fd}, {mode}) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None
