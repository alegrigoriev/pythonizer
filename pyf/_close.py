
def _close(fh):
    global AUTODIE, TRACEBACK, OS_ERROR
    """Implementation of perl close"""
    try:
        if hasattr(fh, '_sp'):      # issue 72: subprocess
            fh.flush()
            fh._sp.communicate()
            if fh._sp.returncode:
                fh.close()
                raise IOError(f"close({fh._file}): failed with {fh._sp.returncode}")
        fh.close()
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return 0


