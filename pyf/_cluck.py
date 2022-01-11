
def _cluck(*args):
    """Warn with stack backtrace"""
    print(_longmess(*args, skip=1), end='', file=sys.stderr)
