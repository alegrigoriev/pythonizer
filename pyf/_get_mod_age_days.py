
def _get_mod_age_days(path):        # -M
    """Implementation of perl -M"""
    if not path:
        return None
    if hasattr(path, '_mtime'):
        t = path._mtime
    else:
        t = os.path.getmtime(path)
    return (BASETIME - t) / 86400.0
    
