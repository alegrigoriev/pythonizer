
def _gmtime(secs=None):
    """Replacement for perl built-in gmtime function"""
    gmt = tm_py.gmtime(secs)
    return (gmt.tm_sec, gmt.tm_min, gmt.tm_hour, gmt.tm_mday, 
            gmt.tm_mon-1, gmt.tm_year-1900, (gmt.tm_wday+1)%7, 
            gmt.tm_yday-1, 0) 

