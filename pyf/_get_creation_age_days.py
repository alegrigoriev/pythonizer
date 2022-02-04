
def _get_creation_age_days(path):       # -C
    if not path:
        return None
    if hasattr(path, '_ctime'):
        t = path._ctime
    else:
        t = os.path.getctime(path)
    return (BASETIME - t) / 86400.0
    
