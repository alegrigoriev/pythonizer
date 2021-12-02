
def _flock(fd, operation):
    """ Replacement for perl Fcntl flock function"""
    global OS_ERROR
    try:
        # To avoid the possibility of miscoordination, Perl now flushes FILEHANDLE before locking or unlocking it.
        fd.flush()
        fcntl.flock(fd, operation)
        return 1
    except Exception as e:
        OS_ERROR = str(_e)
        return 0
    
