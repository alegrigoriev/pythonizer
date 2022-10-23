
def _truncate(fh, length):
    """Implementation of perl $fh->truncate method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if hasattr(fh, 'truncate'):
            fh.truncate(length)
        else:
            os.truncate(fh, length)
        return 1    # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            if isinstance(fh, str):
                _cluck(f"truncate({fh}, {length}) failed: {OS_ERROR}",skip=2)
            else:
                _cluck(f"truncate to {length} failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None

