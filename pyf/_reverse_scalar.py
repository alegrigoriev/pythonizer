
def _reverse_scalar(expr):
    """reverse function implementation in scalar context"""
    if expr is None:
        return ''
    if hasattr(expr, 'isHash'):
        if expr.isHash:
            expr = [_item for _k in expr for _item in (_k, expr[_k])]
        else:
            return ''.join(expr)[::-1]
    elif isinstance(expr, collections.abc.Mapping):  # flatten hash (dict)
        expr = [_item for _k in expr for _item in (_k, expr[_k])]
    if isinstance(expr, collections.abc.Iterable) and not isinstance(expr, str):
        return ''.join(expr)[::-1]
    return expr[::-1]

