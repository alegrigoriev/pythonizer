
def _getA(path):
    """perl -A: Get the start time of the script, minus the time of last
    access of path, in float days"""
    t = os.path.getatime(path)
    return (_script_start - t) / 86400.0
    
