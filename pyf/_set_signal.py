
def _set_signal(sig, handler):
    """Set a signal handler to either a code reference or a string containing a perl code name or IGNORE or DEFAULT"""
    sig = _num(sig)
    if callable(handler):
        signal.signal(sig, handler)
    elif handler == 'IGNORE':
        signal.signal(sig, signal.SIG_IGN)
    elif handler == 'DEFAULT':
        signal.signal(sig, signal.SIG_DFL)
    elif isinstance(handler, str):
        handler = handler.replace('::', '.').replace("'", '.')
        rdot = handler.rfind('.')
        if rdot == -1:
            pkg = getattr(builtins, '__PACKAGE__')
            fun = handler
        else:
            pkg = handler[0:rdot]
            fun = handler[rdot+1:]

        if hasattr(builtins, pkg):
            namespace = getattr(builtins, pkg)
            if hasattr(namespace, fun):
                signal.signal(sig, getattr(namespace, fun))
                return

        def error_handler(sno, frm):
            _warn(f'{signal.Signals(sno).name} handler "{handler}" not defined.\n')

        signal.signal(sig, error_handler)
    else:
        def bad_handler(sno, frm):
            _warn(f"{signal.Signals(sno).name} handler invalid: {handler}.\n")

        signal.signal(sig, bad_handler)
