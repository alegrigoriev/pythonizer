
def _sysseek(fh, pos, how=os.SEEK_SET):
    """Implementation of perl sysseek"""
    return os.lseek(fh.fileno(), pos, how)
