
def _localtime(secs=None):
    """Replacement for perl built-in localtime function"""
    lct = tm_py.localtime(secs)
    return (lct.tm_sec, lct.tm_min, lct.tm_hour, lct.tm_mday, 
            lct.tm_mon-1, lct.tm_year-1900, (lct.tm_wday+1)%7, 
            lct.tm_yday-1, lct.tm_isdst) 

