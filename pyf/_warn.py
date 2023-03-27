
def _warn(*args, skip=None):
    """Handle warn in perl"""
    global INPUT_LINE_NUMBER, _INPUT_FH_NAME
    def is_func_in_call_stack(func):    # Warn handlers are turned off inside themselves
        frame = sys._getframe(2)
        while frame is not None:
            if func.__code__ == frame.f_code:
                return True
            frame = frame.f_back
        return False

    if hasattr(builtins, 'CORE') and hasattr(builtins.CORE, 'GLOBAL') and \
       hasattr(builtins.CORE.GLOBAL, 'warn') and callable(builtins.CORE.GLOBAL.warn) and not \
       is_func_in_call_stack(builtins.CORE.GLOBAL.warn):
        return builtins.CORE.GLOBAL.warn(*args)

    args = list(map(_str, args))
    if len(args) == 0 or len(''.join(args)) == 0:
        args = ["Warning: something's wrong"]
        try:
            if EVAL_ERROR:
                args = [EVAL_ERROR, "\t...caught"]
        except Exception:
            pass

    if "\n" not in args[-1]:
        (_, fn, lno, *_) = _caller() if skip is None else _caller(skip)
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

    if callable(SIG_WARN_HANDLER) and not is_func_in_call_stack(SIG_WARN_HANDLER):
        arg = ''.join(args)
        SIG_WARN_HANDLER(arg)
    else:
        print(*args, sep='', end='', file=sys.stderr)
    return 1
