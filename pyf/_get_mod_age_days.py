
def _get_mod_age_days(path):        # -M
    """Implementation of perl -M"""
    global OS_ERROR, TRACEBACK, AUTODIE
    if not path:
        return None
    if hasattr(path, '_mtime'):
        t = path._mtime
    else:
        try:
            if hasattr(path, 'fileno') and os.stat in os.supports_fd:
                path = path.fileno()
            elif hasattr(path, 'name'):
                path = path.name
            t = os.path.getmtime(path)
        except Exception as _e:
            OS_ERROR = str(_e)
            if TRACEBACK:
                _cluck(f"-M {path} failed: {OS_ERROR}",skip=2)
            if AUTODIE:
                raise
            return 0
    return (BASETIME - t) / 86400.0
    
