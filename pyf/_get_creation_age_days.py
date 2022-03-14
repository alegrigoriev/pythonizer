
def _get_creation_age_days(path):       # -C
    """Implementation of perl -C"""
    global OS_ERROR, TRACEBACK, AUTODIE
    if not path:
        return None
    if hasattr(path, '_ctime'):
        t = path._ctime
    else:
        try:
            t = os.path.getctime(path)
        except Exception as _e:
            OS_ERROR = str(_e)
            if TRACEBACK:
                _cluck(f"-C {path} failed: {OS_ERROR}",skip=2)
            if AUTODIE:
                raise
            return 0
    return (BASETIME - t) / 86400.0
    
