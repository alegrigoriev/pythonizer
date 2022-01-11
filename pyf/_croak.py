
def _croak(*args):
    """Error with no backtrace"""
    raise Die(_shortmess(*args, skip=1))
