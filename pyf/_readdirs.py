
def _readdirs(DIR):
    """Implementation of perl readdir in list context"""
    result = (DIR[0])[DIR[1]:]
    DIR[1] = len(DIR[0])
    return result
