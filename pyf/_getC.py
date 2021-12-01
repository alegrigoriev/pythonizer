
def _getC(path):
    """perl -C: Get the start time of the script, minus the time of last
    creation of path, in float days"""
    t = os.path.getctime(path)
    return (_script_start - t) / 86400.0
    
