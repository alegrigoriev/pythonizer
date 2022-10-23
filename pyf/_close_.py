
def _close_(fh):
    """Implementation of perl close"""
    global AUTODIE, TRACEBACK, OS_ERROR, TRACE_RUN
    try:
        if hasattr(fh, '_sp'):      # issue 72: subprocess
            fh.flush()
            fh._sp.communicate()
            if TRACE_RUN:
                sp = subprocess.CompletedProcess(f"open({fh._file})", fh._sp.returncode)
                _carp(f'trace close({fh._file}): {repr(sp)}', skip=2)
            fh.close()
            if fh._sp.returncode:
                raise IOError(f"close({fh._file}): failed with {fh._sp.returncode}")
            return 1
        if fh is None:
            raise TypeError(f"close(None): failed")
        #if WARNING and fh.closed:
            #_carp(f"close failed: Filehandle is already closed", skip=2)
        fh.close()
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(OS_ERROR,skip=2)
        if AUTODIE:
            raise
        return ''


