
def _setpos(fh, off):
    """Implementation of perl $fh->setpos method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        fh.seek(off, os.SEEK_SET)
        return 1        # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"setpos({off}) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return ''       # False

