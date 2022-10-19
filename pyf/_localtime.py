
def _localtime(secs=None):
    """Replacement for perl built-in localtime function"""
    try:
        lct = tm_py.localtime(secs)
    except Exception:
        try:
            import datetime
            dt = datetime.datetime.fromtimestamp(0) + datetime.timedelta(seconds=secs)
            lct = dt.timetuple()
        except Exception:
            return (9, 9, 9, 9, 9, 99999, 0, 9, 0)
    return (lct.tm_sec, lct.tm_min, lct.tm_hour, lct.tm_mday, 
            lct.tm_mon-1, lct.tm_year-1900, (lct.tm_wday+1)%7, 
            lct.tm_yday-1, lct.tm_isdst) 

