
def _caller(expr=None):
    """ Implementation of caller function in perl"""
    try:
        level = 2 if expr is None else (max(int(expr),0)+2)
        cur = 2
        get_level = 2
        last_level = 1
        while True:
            fr = sys._getframe(get_level)
            if fr.f_code.co_name != '_tie_call' and \
               fr.f_code.co_name != 'tie_call' and \
               fr.f_code.co_name != '_tie_call_func' and \
               fr.f_code.co_name != 'tie_call_func' and \
               fr.f_code.co_name != '<lambda>' and \
               not '__goto_sub__' in fr.f_locals and \
               not re.match(r'^_f\d+[a-z]?$', fr.f_code.co_name):
                cur += 1
                if(cur > level):
                    break
                last_level = get_level
            get_level += 1

        def get_package(fr, get_level):
            fr_tcf = None
            try:
                nfr = sys._getframe(get_level+2)
                if nfr.f_code.co_name == '_tie_call' or \
                   nfr.f_code.co_name == 'tie_call':
                    nfr = sys._getframe(get_level+3)
                    if nfr.f_code.co_name == '_tie_call_func' or \
                       nfr.f_code.co_name == 'tie_call_func' or \
                       nfr.f_code.co_name == '<lambda>':
                        if '__package__' in nfr.f_locals:
                            # We have a variable __package__ defined in _tie_call_func for this purpose
                            # The reason we have that is that all _tie_call_func's code pointers are
                            # the same and we can't tell them apart.
                            if hasattr(nfr.f_locals['__package__'], '__PACKAGE__'):
                                return nfr.f_locals['__package__'].__PACKAGE__
                        fr_tcf = nfr
            except Exception as e:
                pass
            package = None
            try:
                #callable_obj = fr.f_globals[fr.f_code.co_name]
                callable_obj = fr.f_code
                for pack in builtins.__packages__:
                    namespace = getattr(builtins, pack)
                    for key in namespace.__dict__:
                        func = namespace.__dict__[key]
                        if hasattr(func, '__code__'):
                            code = func.__code__
                            if code == callable_obj:
                                package = pack
                                break
                            if fr_tcf and code == fr_tcf.f_code:
                                package = pack
                                break
                        if hasattr(func, '__func__'):   # e.g. MethodType
                            if func.__func__.__code__ == callable_obj:
                                package = pack
                                break
                    if package is not None:
                        break
                else:
                    raise Exception(f"Couldn't find {callable_obj} in {builtins.__packages__}")
            except Exception as e:
                package = 'main'
                if '__PACKAGE__' in fr.f_builtins:
                    package = fr.f_builtins['__PACKAGE__']
            return package

        package = get_package(fr, get_level)

        filename = fr.f_code.co_filename
        if filename == '<string>':  # Running with pdb
            raise ValueError
        if sys.platform == 'win32':
            if os.getcwd().lower() == os.path.dirname(filename).lower():
                filename = os.path.basename(filename)
        else:
            if os.getcwd() == os.path.dirname(filename):
                filename = os.path.basename(filename)
        if expr is None:
            return [package, filename, fr.f_lineno]
        cfr = sys._getframe(last_level)
        while re.match(r'^_f\d+[a-z]?$', cfr.f_code.co_name):
            last_level += 1
            cfr = sys._getframe(last_level)
        cpackage = get_package(cfr, last_level)
        wantarray = ''
        argvalues = inspect.formatargvalues(*inspect.getargvalues(cfr))
        if re.search(r'wantarray=True', argvalues):
            wantarray = 1
        return [package, filename, fr.f_lineno,
                f"{cpackage}.{cfr.f_code.co_name}", 1, wantarray,
                '', 0, 0, 0, 0]
    except ValueError:
        if expr is None:
            return [None, None, None]
        else:
            return [None, None, None, None, None, None, None, None, None, None, None]
        
