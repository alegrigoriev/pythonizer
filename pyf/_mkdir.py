
def _mkdir(path, mode=0o777):
    global TRACEBACK, AUTODIE, OS_ERROR
    """Implementation of perl mkdir function"""
    try:
        os.mkdir(path, mode)
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            if mode == 0o777:
                _cluck(f"mkdir({path}) failed: {OS_ERROR}",skip=2)
            else:
                _cluck(f"mkdir({path}, 0o{mode:o}) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return 0
