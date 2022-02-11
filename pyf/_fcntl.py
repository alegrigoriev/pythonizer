
def _fcntl(fh, func, scalar):
    global AUTODIE, TRACEBACK, OS_ERROR
    """Implementation of perl fcntl"""
    try:
        result = fcntl.fcntl(fh, func, scalar)
        if result == 0:
            return "0 but true"
        if result == -1:
            return None
        return result
    except Exception as e:
        OS_ERROR = str(e)
        if TRACEBACK:
            _cluck(f"fcntl failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None
