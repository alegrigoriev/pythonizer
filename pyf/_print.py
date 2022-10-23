
def _print(fh, *args):
    """Implementation of perl $fh->print method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        print(*args, end='', file=fh)
        return 1        # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"print failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return ''       # False

