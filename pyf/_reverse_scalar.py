
def _reverse_scalar(expr):
    """reverse function implementation in scalar context"""
    if expr is None:
        return ''
    if isinstance(expr, dict):  # flatten hash (dict)
        expr = [_item for _k in expr for _item in (_k, expr[_k])]
    if isinstance(expr, collections.abc.Sequence) and not isinstance(expr, str):
        return ''.join(expr)[::-1]
    return expr[::-1]

