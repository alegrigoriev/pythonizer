
def _chomp_with_result(var):
    """Implementation of chomp where the count of chars removed is needed.  Returns a tuple
    of (result, count)."""
    count = 0
    if var is None:
        var = ''
    if INPUT_RECORD_SEPARATOR is None or isinstance(INPUT_RECORD_SEPARATOR, int):
        return (var, 0)
    if (hasattr(var, 'isHash') and var.isHash) or (not hasattr(var, 'isHash') and isinstance(var, collections.abc.Mapping)):
        for k, v in var.items():
            (var[k], cnt) = _chomp_with_result(v)
            count += cnt
        return (var, count)
    if isinstance(var, collections.abc.Iterable) and not isinstance(var, str):
        for i, v in enumerate(var):
            (var[i], cnt) = _chomp_with_result(v)
            count += cnt
        return (var, count)

    var = str(var)
    if INPUT_RECORD_SEPARATOR == '':
        result = var.rstrip("\n")
    elif var.endswith(INPUT_RECORD_SEPARATOR):
        result = var[0:-len(INPUT_RECORD_SEPARATOR)]
    else:
        result = var
    return (result, len(var) - len(result))
