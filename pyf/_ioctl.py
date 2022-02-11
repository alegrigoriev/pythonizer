
def _ioctl(fh, func, scalar):
    global AUTODIE, TRACEBACK, OS_ERROR
    """Implementation of perl ioctl"""
    try:
        result = fcntl.ioctl(fh, func, scalar)
        if result == 0:
            return "0 but true"
        if result == -1:
            return None
        return result
    except Exception as e:
        OS_ERROR = str(e)
        if TRACEBACK:
            _cluck(f"ioctl failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None
