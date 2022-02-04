
def _eof(fh):
    global AUTODIE, TRACEBACK
    """Implementation of perl eof"""
    try:
        pos = fh.tell()
        return (pos == os.path.getsize(fh))
    except Exception as e:
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return 1


