
def _opendir(DIR):
    """Replacement for perl built-in directory functions"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        return [list(os.listdir(DIR)), 0]
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"opendir({DIR}) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None
