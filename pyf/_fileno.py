
def _fileno(fh):
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if isinstance(fh, list) and len(fh) == 2 and isinstance(fh[0], list) and isinstance(fh[1], int):    # DIRHANDLE
            raise TypeError("Directories have no associated fileno");
        return fh.fileno()
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"fileno failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None

