
def _run_s(*args):
    """Execute a command and return the stdout in scalar context"""
    global CHILD_ERROR, AUTODIE, TRACEBACK, TRACE_RUN
    if len(args) == 1:
        args = args[0]
    try:
        sp = subprocess.run(args,capture_output=True,text=True,shell=_need_sh(args))
    except FileNotFoundError:   # can happen on windows if shell=False
        sp = subprocess.CompletedProcess(args, 127)
    except OSError:             # check if we're trying to run a perl or python script on Windows
        if isinstance(args, str):
            args = [args]
        arg_split = args[0].split()[0]
        if arg_split.endswith('.py'):
            args = [sys.executable] + args
        elif arg_split.endswith('.pl'):
            args = ['perl'] + args
        else:
            raise
        sp = subprocess.run(args,capture_output=True,text=True,shell=_need_sh(args))
    if TRACE_RUN:
        _carp(f'trace run({args}): {repr(sp)}', skip=2)
    CHILD_ERROR = sp.returncode
    if CHILD_ERROR:
        if AUTODIE:
            raise Die(f'run({args}): failed with rc {CHILD_ERROR}')
        if TRACEBACK:
            _cluck(f'run({args}): failed with rc {CHILD_ERROR}',skip=2)
    return sp.stdout
