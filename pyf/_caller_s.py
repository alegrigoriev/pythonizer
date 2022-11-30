
def _caller_s(expr=None):
    """ Implementation of caller function in scalar context"""
    try:
        fr = sys._getframe(2 if expr is None else (max(int(expr),0)+1))
        package = 'main'
        if hasattr(fr.f_builtins, '__PACKAGE__'):
            package = fr.f_builtins.__PACKAGE__
        return package
    except ValueError:
        return None
