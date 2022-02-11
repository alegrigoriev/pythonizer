
def _eof(fh):
    global AUTODIE, TRACEBACK
    """Implementation of perl eof"""
    try:
        pos = fh.tell()
        return (pos == os.path.getsize(fh))
    except Exception as e:
        if TRACEBACK:
            _cluck(f"eof failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return 1


