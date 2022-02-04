
def _setpos(fh, off):
    """Implementation of perl $fh->seek method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        fh.seek(off, os.SEEK_SET)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return False

