
def _chdir(d):
    """Implementation of perl chdir"""
    global AUTODIE, TRACEBACK, OS_ERROR
    try:
        os.chdir(d)
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(OS_ERROR,skip=2)
        if AUTODIE:
            raise
        return ''


