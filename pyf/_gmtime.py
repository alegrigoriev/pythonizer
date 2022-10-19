
def _gmtime(secs=None):
    """Replacement for perl built-in gmtime function"""
    try:
        gmt = tm_py.gmtime(secs)
    except Exception:
        try:
            import datetime
            dt = datetime.datetime.utcfromtimestamp(0) + datetime.timedelta(seconds=secs)
            gmt = dt.timetuple()
        except Exception:
            return (9, 9, 9, 9, 9, 99999, 0, 9, 0)
    return (gmt.tm_sec, gmt.tm_min, gmt.tm_hour, gmt.tm_mday, 
            gmt.tm_mon-1, gmt.tm_year-1900, (gmt.tm_wday+1)%7, 
            gmt.tm_yday-1, 0) 

