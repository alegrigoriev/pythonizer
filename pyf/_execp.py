
def _execp(program, lst):
    """Implementation of perl exec with a program and a list"""
    global OS_ERROR, TRACEBACK
    try:
        sys.stdout.flush()
        sys.stderr.flush()
    except Exception:
        pass

    try:
        os.execvp(program, list(lst))
    except OSError:     # checkif we're trying to run a perl or python script on Windows
        if isinstance(program, str):
            program_split = program.split()[0]
            if program_split.endswith('.py'):
                lst = [program] + lst
                program = sys.executable
            elif program_split.endswith('.pl'):
                lst = [program] + lst
                program = 'perl'
            else:
                raise
            os.execvp(program, list(lst))
        else:
            raise
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"exec({program, lst}) failed: {OS_ERROR}", skip=2)
