
def _get_access_age_days(path):        # -A
    """Implementation of perl -A"""
    global OS_ERROR, TRACEBACK, AUTODIE
    if not path:
        return None
    if hasattr(path, '_atime'):
        t = path._atime
    else:
        try:
            t = os.path.getatime(path)
        except Exception as _e:
            OS_ERROR = str(_e)
            if TRACEBACK:
                _cluck(f"-A {path} failed: {OS_ERROR}",skip=2)
            if AUTODIE:
                raise
            return 0
    return (BASETIME - t) / 86400.0
    
