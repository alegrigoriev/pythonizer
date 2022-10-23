
def _seek(fh, pos, whence):
    """Implementation of perl seek"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        return fh.seek(pos, whence)
        return 1        # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"seek({pos},{whence}) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None

