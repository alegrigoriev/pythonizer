
def _tell(fh):
    """Implementation of perl tell"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        return fh.tell()
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"tell failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return -1

