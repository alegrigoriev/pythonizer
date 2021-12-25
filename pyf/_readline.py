
def _readline(fh):
    """Reads a line from a file.
    (instead use _readline_full if you need support for perl $/ or $.)"""
    result = fh.readline()
    if not result:
        return None
    return result

