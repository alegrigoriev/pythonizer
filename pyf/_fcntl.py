
def _fcntl(fh, func, scalar):
    global AUTODIE, TRACEBACK
    """Implementation of perl fcntl"""
    try:
        return fcntl.fcntl(fh, func, scalar)
    except Exception as e:
        if TRACEBACK:
            traceback.print_exc()
        raise
