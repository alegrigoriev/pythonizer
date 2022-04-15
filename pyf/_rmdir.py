
def _rmdir(d):
    """Implementation of perl rmdir"""
    global AUTODIE, TRACEBACK, OS_ERROR
    try:
        os.rmdir(d)
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(OS_ERROR,skip=2)
        if AUTODIE:
            raise
        return 0


