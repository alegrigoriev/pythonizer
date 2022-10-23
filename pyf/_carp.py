
def _carp(*args,skip=1):
    """Warn with no backtrace"""
    if TRACEBACK:
        print(_longmess(*args, skip=skip), end='', file=sys.stderr)
    else:
        print(_shortmess(*args, skip=skip), end='', file=sys.stderr)
    return 1
