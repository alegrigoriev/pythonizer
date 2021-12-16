
def _timelocal(sec, min, hour, mday, mon, year, wday=0, yday=0, isdst=0):
    """Replacement for perl built-in timelocal function"""
    if year < 1900:
        year += 1900
    return tm_py.mktime((year, mon+1, mday, hour, min, sec, 0, 1, -1))

