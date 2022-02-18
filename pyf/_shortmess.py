
def _shortmess(*args, skip=0):
    """Message with no backtrace"""
    def ff(fn):
        fn = os.path.relpath(fn)
        if fn.startswith('./'):
            return fn[2:]
        return fn
    stack = inspect.stack()
    stack = stack[skip:]
    m = ''.join(map(str, args))
    m += ' at ' + ff(stack[1].filename) + ' line ' + str(stack[1].lineno) + ".\n"
    return m
