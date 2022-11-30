
def _sysread(fh, var, length, offset=0, need_len=False):
    """Read length bytes from the fh, and return the result to store in var
       if need_len is False, else return a tuple with the result
       and the length read.  For compatability with perl, the
       result is returned as a str, not bytes."""
    global OS_ERROR, TRACEBACK, AUTODIE
    if var is None:
        var = ''
    try:
        s = str(os.read(fh.fileno(), length), encoding='latin1', errors='ignore')
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"sysread of {length} bytes failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        if need_len:
            return (var, None)
        return var

    ls = len(s)
    lv = len(var)
    if offset < 0:
        offset += lv
    if offset:
        if need_len:
            return (var[:offset] + ('\0' * (offset-lv)) + s, ls)
        else:
            return var[:offset] + ('\0' * (offset-lv)) + s
    if need_len:
        return (s, ls)
    return s
