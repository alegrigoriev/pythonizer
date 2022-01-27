
def _make_list(expr):
    """For push/unshift @arr, expr;  We use extend/[0:0] so make sure expr is iterable"""
    if isinstance(expr, collections.abc.Iterable) and not isinstance(expr, str):
        return expr
    return [expr]

