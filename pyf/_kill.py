
def _kill(sig, *args):
    """Implementation of perl kill function"""
    global AUTODIE, TRACEBACK, OS_ERROR
    if isinstance(sig, str):
        neg = 1
        if sig.startswith('-'):
            neg = -1
        if not sig.startswith('SIG'):
            sig = f"SIG{sig}"
        if not sig in signal.Signals:
            _carp(f'Unrecognized signal name "{sig}"')
            return 0
        sig = signal.Signals[sig] * neg
    result = 0
    for pid in args:
        try:
            os.kill(pid, sig)
            result += 1
        except Exception as _e:
            OS_ERROR = str(_e)
            if TRACEBACK:
                _cluck(f"kill({sig}, {pid}) failed: {OS_ERROR}", skip=2)
            if AUTODIE:
                raise
    return result

