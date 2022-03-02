
def _num(expr):
    """Convert expr to a number
       Ref: https://squareperl.com/en/how-perl-convert-string-to-number"""
    if not expr:
        return 0
    try:
        return +expr    # Unary plus: The fastest way to test for numeric
    except Exception:
        pass
    #if isinstance(expr, (int, float)):
        #return expr
    try:
        return int(expr)
    except Exception:
        pass
    for _ in range(2):
        try:
            f = float(expr)
            if f.is_integer():
                return int(f)
            return f
        except Exception:
            pass
        if isinstance(expr, str):
            if not (m:=re.match(r'^\s*([+-]?(?:\d+(?:[.]\d*)?(?:[eE][+-]?\d+)?|[.]\d+(?:[eE][+-]?\d+)?))', expr)):
                break
            expr = m.group(1);
        elif isinstance(expr, bytes):
            if not (m:=re.match(br'^\s*([+-]?(?:\d+(?:[.]\d*)?(?:[eE][+-]?\d+)?|[.]\d+(?:[eE][+-]?\d+)?))', expr)):
                break
            expr = m.group(1);
        else:
            return expr
    if WARNING:
        caller = inspect.getframeinfo(inspect.stack()[1][0])
        warnings.warn(f"Argument \"{expr}\" isn't numeric in numeric context at {caller.filename}:{caller.lineno}")
    return 0
