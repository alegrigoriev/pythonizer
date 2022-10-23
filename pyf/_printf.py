
def _printf(fh, fmt, *args):
    """Implementation of perl $fh->printf method"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        print(_format(fmt, *args), end='', file=fh)
        return 1        # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            if isinstance(fmt, str):
                fmt = fmt.replace("\n", '\\n')
            _cluck(f"printf({fmt},...) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return ''       # False

