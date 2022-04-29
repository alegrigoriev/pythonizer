
def _strftime(fmt, sec, min=None, hour=None, mday=None, mon=None, year=None, wday=0, yday=0, isdst=0):
    """Implementation of perl strftime"""
    if min is None:
        min = sec[1]
        hour = sec[2]
        mday = sec[3]
        mon = sec[4]
        year = sec[5]
        sec = sec[0]
    tl = _timelocal(sec, min, hour, mday, mon, year)
    return tm_py.strftime(fmt, tm_py.localtime(tl))
