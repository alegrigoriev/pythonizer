
def _printf(fh, fmt, *args):
    """Implementation of perl $fh->printf method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        print(_format(fmt, *args), end='', file=fh)
        return True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return False

