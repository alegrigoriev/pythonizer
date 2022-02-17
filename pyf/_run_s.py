
def _run_s(*args):
    """Execute a command and return the stdout in scalar context"""
    global CHILD_ERROR, AUTODIE, TRACEBACK
    if len(args) == 1:
        args = args[0]
    sp = subprocess.run(args,capture_output=True,text=True,shell=True)
    CHILD_ERROR = sp.returncode
    if CHILD_ERROR:
        if AUTODIE:
            raise Die(f'run({args}): failed with rc {CHILD_ERROR}')
        if TRACEBACK:
            _cluck(f'run({args}): failed with rc {CHILD_ERROR}',skip=2)
    return sp.stdout
