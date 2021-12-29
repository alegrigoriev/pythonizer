
def _caller(expr=None):
    """ Implementation of caller function in perl"""
    try:
        fr = sys._getframe(2 if expr is None else (max(int(expr),0)+1))
        package = 'main'
        if hasattr(fr.f_builtins, '__PACKAGE__'):
            package = fr.f_builtins.__PACKAGE__
        if expr is None:
            return [package, fr.f_code.co_filename, fr.f_lineno]
        return [package, fr.f_code.co_filename, fr.f_lineno,
                fr.f_code.co_name, fr.f_code.co_argcount, 1,
                '', 0, 0, 0, 0]
    except ValueError:
        return None
