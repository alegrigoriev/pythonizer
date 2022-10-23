
def _say(fh, *args):
    """Implementation of perl $fh->say method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        print(*args, file=fh)
        return 1        # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"say failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return ''       # False

