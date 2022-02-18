
def _system(*args):
    """Execute a command and return the return code"""
    global CHILD_ERROR, AUTODIE, TRACEBACK, TRACE_RUN
    if len(args) == 1:
        args = args[0]
    sp = subprocess.run(args,capture_output=True,text=True,shell=True)
    if TRACE_RUN:
        _carp(f'trace system({args}): {repr(sp)}', skip=2)
    CHILD_ERROR = sp.returncode
    if CHILD_ERROR:
        if AUTODIE:
            raise Die(f'system({args}): failed with rc {CHILD_ERROR}')
        if TRACEBACK:
            _cluck(f'system({args}): failed with rc {CHILD_ERROR}',skip=2)
    return CHILD_ERROR
