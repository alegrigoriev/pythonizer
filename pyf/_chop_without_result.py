
def _chop_without_result(var):
    """Implementation of chop where the last char removed is not needed.  Returns a tuple
    of (result, '')."""
    if var is None:
        var = ''
    if (hasattr(var, 'isHash') and var.isHash) or (not hasattr(var, 'isHash') and isinstance(var, collections.abc.Mapping)):
        for k, v in var.items():
            (var[k], _) = _chop_without_result(v)
        return (var, '')
    if isinstance(var, collections.abc.Iterable) and not isinstance(var, str):
        for i, v in enumerate(var):
            (var[i], _) = _chop_without_result(v)
        return (var, '')

    var = str(var)
    result = var[0:-1]
    return (result, '')
