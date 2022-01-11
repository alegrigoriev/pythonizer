
def _carp(*args):
    """Warn with no backtrace"""
    print(_shortmess(*args, skip=1), end='', file=sys.stderr)
