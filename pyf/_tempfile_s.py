
def _tempfile_s(*args):
    """Implementation of File::Temp::tempfile() in scalar context"""
    (fh, _) = _tempfile_(*args)
    return fh
