
def timelocal(sec, min, hour, mday, mon, year):
    """Replacement for perl built-in timelocal function"""
    return tm_py.mktime((year+1900, mon+1, mday, hour, min, sec, 0, 1, -1))

