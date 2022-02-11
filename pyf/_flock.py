
def _flock(fd, operation):
    """ Replacement for perl Fcntl flock function"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        # To avoid the possibility of miscoordination, Perl now flushes FILEHANDLE before locking or unlocking it.
        fd.flush()
        fcntl.flock(fd, operation)
        return 1
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"flock failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return 0
    
