
def _close(fh):
    global AUTODIE, TRACEBACK
    """Implementation of perl close"""
    try:
        fh.close()
        return 1
    except Exception as e:
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return 0


