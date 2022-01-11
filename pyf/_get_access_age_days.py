
def _get_access_age_days(path):        # -A
    if not path:
        return None
    if hasattr(path, 'atime'):
        t = path.atime
    else:
        t = os.path.getatime(path)
    return (BASETIME - t) / 86400.0
    
