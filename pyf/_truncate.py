
def _truncate(fh, length):
    """Implementation of perl $fh->truncate method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        os.truncate(fh, length)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return None

