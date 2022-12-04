
def _init_out_parameters(arglist, *_args):
    """Initialize sub's out parameters.  Pass the arglist of the sub
    and a list of the sub's out parameters, counting from 0.  If no
    list is passed, then all args are assumed to be out parameters"""
    if len(_args) == 0:
        for i in range(len(arglist)):
            try:
                setattr(builtins, f"__outp{i}__", arglist[i])
            except Exception:
                pass
        return

    for i in _args:
        try:
            setattr(builtins, f"__outp{i}__", arglist[i])
        except Exception:
            pass
