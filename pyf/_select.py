
def _select(fh):
    """Implementation of perl select function"""
    result = sys.stdout
    sys.stdout = fh
    return result
