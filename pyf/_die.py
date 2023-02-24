

def _die(*args):
    """Handle die in perl"""
    global INPUT_LINE_NUMBER, _INPUT_FH_NAME, EVAL_ERROR
    def is_func_in_call_stack(func):    # Die handlers are turned off inside themselves
        frame = sys._getframe(2)
        while frame is not None:
            if func.__code__ == frame.f_code:
                return True
            frame = frame.f_back
        return False

    if hasattr(builtins, 'CORE') and hasattr(builtins.CORE, 'GLOBAL') and \
       hasattr(builtins.CORE.GLOBAL, 'die') and callable(builtins.CORE.GLOBAL.die) and not \
       is_func_in_call_stack(builtins.CORE.GLOBAL.die):
        return builtins.CORE.GLOBAL.die(*args)

    args = list(map(_str, args))
    if len(args) == 0 or len(''.join(args)) == 0:
        args = ["Died"]
        try:
            if EVAL_ERROR or hasattr(EVAL_ERROR, 'PROPAGATE'):
                if hasattr(EVAL_ERROR, 'PROPAGATE') and callable(EVAL_ERROR.PROPAGATE):
                    (_, fn, lno) = _caller()
                    try:
                        EVAL_ERROR = EVAL_ERROR.PROPAGATE(fn, lno)
                        args = [EVAL_ERROR]
                    except Exception:
                        args = [EVAL_ERROR, "\t...propagated"]
                else:
                    args = [EVAL_ERROR, "\t...propagated"]
        except Exception:
            pass

    if "\n" not in args[-1]:
        (_, fn, lno) = _caller()
        iln = None
        ifn = None
        try:
            iln = fileinput.lineno()
            ifn = '<fileinput>'
        except RuntimeError:
            iln = INPUT_LINE_NUMBER
            if _INPUT_FH_NAME:
                ifn = f"<{_INPUT_FH_NAME}>"

        if iln and ifn:
            args.append(f" at {fn} line {lno}, {ifn} line {iln}.\n")
        else:
            args.append(f" at {fn} line {lno}.\n")

    arg = ''.join(args)
    if callable(SIG_DIE_HANDLER) and not is_func_in_call_stack(SIG_DIE_HANDLER):
        SIG_DIE_HANDLER(arg)
    orig_excepthook = sys.excepthook
    def excepthook(typ, value, traceback):
        if TRACEBACK:
            orig_excepthook(typ, value, traceback)
        else:
            print(value, end='', file=sys.stderr)
        if (m := re.search(r'\[Errno (\d+)\]', str(value))):
            sys.exit(int(m.group(1)))
        if CHILD_ERROR>>8:
            sys.exit(CHILD_ERROR>>8)
        sys.exit(255)

    sys.excepthook = excepthook
    raise Die(arg)
