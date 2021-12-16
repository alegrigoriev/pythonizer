
def _timegm(sec, min, hour, mday, mon, year, wday=0, yday=0, isdst=0):
    """Replacement for perl built-in timegm function"""
    if year < 1900:
        year += 1900
    return calendar.timegm((year, mon+1, mday, hour, min, sec, 0, 1, -1))

