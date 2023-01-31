
def _read(fh, var, length, offset=0, need_len=False):
    """Read length bytes from the fh, and return the result to store in var
       if need_len is False, else return a tuple with the result
       and the length read"""
    global OS_ERROR, TRACEBACK, AUTODIE
    if var is None:
        var = ''
    try:
        s = fh.read(length)
        if isinstance(s, bytes):
            s = str(s, encoding='latin1', errors='ignore')
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"read of {length} byte(s) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        if need_len:
            return (var, None)
        return var

    ls = len(s)
    var = _str(var)
    lv = len(var)
    if offset < 0:
        offset += lv
    if offset:
        if isinstance(var, bytes):
            var = var.decode(encoding='latin1',  errors='ignore')
        if need_len:
            return (var[:offset] + ('\0' * (offset-lv)) + s, ls)
        else:
            return var[:offset] + ('\0' * (offset-lv)) + s
    if need_len:
        return (s, ls)
    return s
