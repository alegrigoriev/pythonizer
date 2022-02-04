
def _ioctl(fh, func, scalar):
    global AUTODIE, TRACEBACK
    """Implementation of perl ioctl"""
    try:
        return fcntl.ioctl(fh, func, scalar)
    except Exception as e:
        if TRACEBACK:
            traceback.print_exc()
        raise
