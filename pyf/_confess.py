
def _confess(*args,skip=1):
    """Error with stack backtrace"""
    if TRACEBACK:
        raise Die(_longmess(*args, skip=skip),suppress_traceback=True)
    raise Die(_longmess(*args, skip=skip))
