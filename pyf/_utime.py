
def _utime(atime, mtime, *args):
    """Implementation of perl utime function"""
    global TRACEBACK, AUTODIE, OS_ERROR
    result = 0
    OS_ERROR = ''
    times = None
    if atime is None and mtime is None:
        pass
    elif atime is None:
        atime = 0
    elif mtime is None:
        mtime = 0
    times = (atime, mtime)
    for fd in args:
        try:
            if hasattr(fd, 'fileno') and os.utime in os.supports_fd:
                fd = fd.fileno()
            elif hasattr(fd, 'name'):
                fd = fd.name
            os.utime(fd, times)
            result += 1
        except Exception as _e:
            OS_ERROR = str(_e)
            if TRACEBACK:
                _cluck(f"utime({atime}, {mtime}, {fd}) failed: {OS_ERROR}",skip=2)
            if AUTODIE:
                raise
    return result


