
def _chop_with_result(var):
    """Implementation of chop where the last char removed is needed.  Returns a tuple
    of (result, last_c)."""
    if var is None:
        var = ''
    if (hasattr(var, 'isHash') and var.isHash) or (not hasattr(var, 'isHash') and isinstance(var, collections.abc.Mapping)):
        for k, v in var.items():
            (var[k], last_c) = _chop_with_result(v)
        return (var, last_c)
    if isinstance(var, collections.abc.Iterable) and not isinstance(var, str):
        for i, v in enumerate(var):
            (var[i], last_c) = _chop_with_result(v)
        return (var, last_c)

    var = str(var)
    last_c = var[-1:]
    result = var[0:-1]
    return (result, last_c)
