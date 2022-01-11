
def _get_mod_age_days(path):        # -M
    if not path:
        return None
    if hasattr(path, 'mtime'):
        t = path.mtime
    else:
        t = os.path.getmtime(path)
    return (BASETIME - t) / 86400.0
    
