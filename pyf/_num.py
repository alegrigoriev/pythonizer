
def _num(expr):
    """Convert expr to a number"""
    if not expr:
        return 0
    if isinstance(expr, (int, float)):
        return expr
    try:
        return int(expr)
    except Exception:
        pass
    try:
        return float(expr)
    except Exception:
        # FIXME: Check for a prefix that's a float number, and return that
        # see: https://squareperl.com/en/how-perl-convert-string-to-number
        caller = inspect.getframeinfo(inspect.stack()[1][0])
        warnings.warn(f"Argument \"{expr}\" isn't numeric in numeric context at {caller.filename}:{caller.lineno}")
    return 0
