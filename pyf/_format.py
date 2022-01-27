
def _format(fmt, args=None):
    """Like % formatter in python, but auto-converts the args to the proper types"""
    fmt = str(fmt)
    if args is None:
        return fmt % ()
    if isinstance(args, collections.abc.Iterable) and not isinstance(args, str):
        args = list(args)
    else:
        args = [args]
    fmt_regex = re.compile(r'%(?:[#0+ -])*(\*|\d+)?([.](?:\*|\d+))?[hlL]?([diouxXeEfFgGcrsa])')
    num_fmts = set('diouxXeEfFgG')
    i = 0
    for m in re.finditer(fmt_regex, fmt.replace('%%', '')):
        if m.group(1) == '*':
            args[i] = _int(args[i])
            i += 1
        if m.group(2) == '.*':
            args[i] = _int(args[i])
            i += 1
        if m.group(3) in num_fmts:
            args[i] = _num(args[i])
        i += 1
    return fmt % tuple(args)

