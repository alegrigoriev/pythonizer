
def _caller(expr=None):
    """ Implementation of caller function in perl"""
    try:
        fr = sys._getframe(2 if expr is None else (max(int(expr),0)+1))
        package = None
        try:
            callable_obj = fr.f_globals[fr.f_code.co_name]
            for pack in builtins.__packages__:
                namespace = getattr(builtins, pack)
                for key in namespace.__dict__:
                    func = namespace.__dict__[key]
                    if func == callable_obj:
                        package = pack
                        break
                    if hasattr(func, '__func__'):
                        if func.__func__ == callable_obj:
                            package = pack
                            break
                if package is not None:
                    break
        except Exception:
            package = 'main'
            if '__PACKAGE__' in fr.f_builtins:
                package = fr.f_builtins['__PACKAGE__']
        filename = fr.f_code.co_filename
        if os.getcwd() == os.path.dirname(filename):
            filename = os.path.basename(filename)
        if expr is None:
            return [package, filename, fr.f_lineno]
        return [package, filename, fr.f_lineno,
                f"{package}.{fr.f_code.co_name}", fr.f_code.co_argcount, 1,
                '', 0, 0, 0, 0]
    except ValueError:
        return None
