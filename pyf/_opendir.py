
def _opendir(DIR):
    """Replacement for perl built-in directory functions"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        return [list(os.listdir(DIR)), 0]
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return None
