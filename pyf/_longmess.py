
def _longmess(*args, skip=0):
    """Message with stack backtrace"""
    def ff(fn):
        fn = os.path.relpath(fn)
        if fn.startswith('./'):
            return fn[2:]
        return fn
    def fa(a):
       return re.sub(r'^\(\*_args=(.*)\)$', r'\1',a).replace(',)', ')')
    stack = inspect.stack()
    stack = stack[skip:]
    m = ''.join(map(str, args))
    m += ' at ' + ff(stack[1].filename) + ' line ' + str(stack[1].lineno) + ".\n"
    for i in range(1, len(stack)-1):
       s = stack[i]
       s2 = stack[i+1]
       m += '        ' + s.function+fa(inspect.formatargvalues(*inspect.getargvalues(s.frame))) + ' called at ' + ff(s2.filename) + ' line ' + str(s2.lineno) + "\n"
    return m
