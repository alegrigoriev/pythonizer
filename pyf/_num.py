
def _num(expr):
    """Convert expr to a number
       Ref: https://squareperl.com/en/how-perl-convert-string-to-number"""
    if expr is None:
        return 0
    try:
        return +expr    # Unary plus: The fastest way to test for numeric
    except Exception:
        pass
    #if isinstance(expr, (int, float)):
        #return expr
    #try:
        #return int(expr)
    #except Exception:
        #pass
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
        elif hasattr(expr, 'isHash') and expr.isHash is None:
            return 0
        elif isinstance(expr, object) and hasattr(expr, '__class__') and isinstance(expr.__class__, type):    # a perl object
            if hasattr(expr, '_num_') and callable(expr._num_):
                return expr._num_()         # use overload "0+"
            # Breaks Math::Complex operations!  return id(expr)     # Objects in == are compared by address
            return expr
        else:
            return expr
    if WARNING == 2:
        _die(f"Argument \"{expr}\" isn't numeric in numeric context", skip=1)
    if WARNING:
        # caller = inspect.getframeinfo(inspect.stack()[1][0])
        # warnings.warn(f"Argument \"{expr}\" isn't numeric in numeric context at {caller.filename}:{caller.lineno}")
        _warn(f"Argument \"{expr}\" isn't numeric in numeric context", skip=1)
    return 0
