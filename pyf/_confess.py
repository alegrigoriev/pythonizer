
def _confess(*args,skip=1):
    """Error with stack backtrace"""
    raise Die(_longmess(*args, skip=skip),suppress_traceback=True)
