
def _openhandle(fh):
    """Return the file handle if this is an opened file handle, else return None"""
    if hasattr(fh, 'closed'):
        if not fh.closed:
            return fh
    return None
