
def _confess(*args):
    """Error with stack backtrace"""
    raise Die(_longmess(*args, skip=1))
