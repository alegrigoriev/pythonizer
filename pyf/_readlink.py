
def _readlink(path):
    """Returns the value of a symbolic link.  If there is a system error, returns the undefined value and sets OS_ERROR (errno)."""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        return os.readlink(path)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"readlink({path}) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None

