
def _cluck(*args,skip=1):
    """Warn with stack backtrace"""
    print(_longmess(*args, skip=skip), end='', file=sys.stderr)
