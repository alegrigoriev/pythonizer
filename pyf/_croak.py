
def _croak(*args,skip=1):
    """Error with no backtrace"""
    if TRACEBACK:
        raise Die(_longmess(*args, skip=skip),suppress_traceback=True)
    raise Die(_shortmess(*args, skip=skip))
