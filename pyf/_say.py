
def _say(fh, *args):
    """Implementation of perl $fh->say method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        print(*args, file=fh)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return False

