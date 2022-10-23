
def _int(expr):
    """Convert expr to an integer"""
    if not expr:
        return 0
    if isinstance(expr, int):
        return +expr            # The Unary plus will convert True to 1
    try:
        return int(expr)
    except Exception:
        pass
    if not isinstance(expr, (str, bytes)):
        if isinstance(expr, complex):
            return _int(expr.real)
        return expr
    if (m:=re.match(r'^\s*([+-]?(?:\d+))', expr)):
        return int(m.group(1))
    if WARNING:
        caller = inspect.getframeinfo(inspect.stack()[1][0])
        warnings.warn(f"Argument \"{expr}\" isn't numeric in integer context at {caller.filename}:{caller.lineno}")
    return 0
