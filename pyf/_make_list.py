
def _make_list(*args):
    """For push/unshift @arr, expr;  We use extend/[0:0] so make sure expr is iterable"""
    if len(args) == 1 and isinstance(args[0], collections.abc.Iterable) and not isinstance(args[0], str):
        return args[0]
    return args

