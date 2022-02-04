
def _print(fh, *args):
    """Implementation of perl $fh->print method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        print(*args, end='', file=fh)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return False

