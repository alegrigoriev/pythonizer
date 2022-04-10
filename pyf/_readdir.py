
def _readdir(DIR):
    """Implementation of perl readdir in scalar context"""
    try:
        result = (DIR[0])[DIR[1]]
        DIR[1] += 1
        return result
    except IndexError:
        return None
