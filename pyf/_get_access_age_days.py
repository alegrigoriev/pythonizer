
def _get_access_age_days(path):        # -A
    """Implementation of perl -A"""
    if not path:
        return None
    if hasattr(path, '_atime'):
        t = path._atime
    else:
        t = os.path.getatime(path)
    return (BASETIME - t) / 86400.0
    
