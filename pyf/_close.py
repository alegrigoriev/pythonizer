
def _close(fh):
    """Implementation of perl close"""
    global AUTODIE, TRACEBACK, OS_ERROR
    try:
        if hasattr(fh, '_sp'):      # issue 72: subprocess
            fh.flush()
            fh._sp.communicate()
            if fh._sp.returncode:
                fh.close()
                raise IOError(f"close({fh._file}): failed with {fh._sp.returncode}")
        if fh is None:
            raise TypeError(f"close(None): failed")
        if fh.closed:
            raise IOError(f"close failed: Filehandle is already closed")
        fh.close()
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(OS_ERROR,skip=2)
        if AUTODIE:
            raise
        return 0


