
def _mkdir(path, mode=0o777):
    global TRACEBACK, AUTODIE, OS_ERROR
    """Implementation of perl mkdir function"""
    try:
        os.mkdir(path, mode)
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return 0
