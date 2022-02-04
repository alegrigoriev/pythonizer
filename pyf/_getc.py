
def _getc(fh):
    """Implementation of perl getc"""
    fh._last_pos = fh.tell()    # for ungetc
    return fh.read(1)
