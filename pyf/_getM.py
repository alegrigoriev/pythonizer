
def _getM(path):
    """perl -M: Get the start time of the script, minus the time of last
    modification of path, in float days"""
    t = os.path.getmtime(path)
    return (_script_start - t) / 86400.0
    
