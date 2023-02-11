
def _import(globals, path, module=None, fromlist=None, version=None, is_do=False):
    """Handle use/require statement from perl.  'path' is the relative or absolute path to the .py file
    of the module (the extension is ignored if specified).  If 'module' is specified, then that is
    effectively added to the path, 'fromlist' is the list of desired functions to import.  'version'
    will perform a version check. 'is_do' handles a 'do EXPR;' statement."""
    global OS_ERROR, EVAL_ERROR
    if not hasattr(builtins, '__PACKAGE__'):
        caller_package = 'main'
    else:
        caller_package = builtins.__PACKAGE__
    pathname = None
    if module is not None:
        path = f'{path}/{module}'
        module = None
    if not os.path.isabs(path):
        path = os.path.splitext(path)[0]
        pathname = path.replace('.', '').replace('/', '.')
        if pathname[0] == '.':
            pathname = pathname[1:]
        if path[0] == '.':
            pass
        else:
            for pa in sys.path:
                if os.path.isfile(os.path.join(pa, path, '__init__.py')):
                    path = os.path.join(pa, path)
                    break
                elif os.path.isfile(os.path.join(pa, f'{path}.py')):
                    path = os.path.join(pa, path)
                    break
            else:
                if not is_do:
                    msg = f"Can't locate {path}.py in sys.path (sys.path contains: {' '.join(sys.path)})"
                    raise ImportError(msg)
    [path, module] = os.path.split(os.path.splitext(os.path.abspath(path))[0])
    if is_do:
        sys.modules.pop(module, None)
    if module in sys.modules and \
      hasattr((mod:=sys.modules[module]), '__file__') and \
      os.path.join(path, module) + '.py' == mod.__file__:
       pass
    else:
        try:
            sys.path.insert(0, path)
            mod = __import__(module, globals=globals, fromlist=['*'])
            sys.modules[module] = mod
        except ImportError as _i:
            if is_do:
                OS_ERROR = str(_i)
                return None
            else:
                raise
        except Exception as _e:
            if is_do:
                EVAL_ERROR = str(_e)
                return None
            else:
                raise
        finally:
            sys.path.pop(0)

    if hasattr(mod, 'VERSION') and version is not None:
        if isinstance(version, str) and version[0] == 'v':
            version = version[1:]
        try:
            version = float(version)
        except Exception:
            version = 0.0
        mod_version = None
        try:
            mod_version = float(mod.VERSION)
        except Exception:
            pass
        if mod_version is not None and version > mod_version:
            raise ValueError(f"For import {module}, desired version {version} > actual version {mod_version} at {path}")

    # globals[module] = mod

    if fromlist is None:
        return 1                 # use X ();

    if not isinstance(fromlist, (list, tuple)):
        fromlist = [fromlist]

    actual_imports = set()
    export = ()
    export_ok = ()
    export_tags = dict()
    for pn in (pathname, builtins.__PACKAGE__):     # builtins.__PACKAGE__ is now the module's package, not ours
        if pn is not None and hasattr(builtins, pn):
            module_namespace = getattr(builtins, pn)
            if hasattr(module_namespace, 'EXPORT_a'):
                export = getattr(module_namespace, 'EXPORT_a')
            if hasattr(module_namespace, 'EXPORT_OK_a'):
                export_ok = getattr(module_namespace, 'EXPORT_OK_a')
            if hasattr(module_namespace, 'EXPORT_TAGS_h'):
                export_tags = getattr(module_namespace, 'EXPORT_TAGS_h')

    builtins.__PACKAGE__ = caller_package
    if (fromlist[0] == '*' or fromlist[0] == ':all') and hasattr(mod, '__all__'):
        actual_imports = set(mod.__all__)
    elif fromlist[0] == '*' and not export:
        for key in mod.__dict__.keys():
            if callable(mod.__dict__[key]) and key[0] != '_':
                actual_imports.add(key)
    else:
        # This should mirror the code in pythonizer expand_extras:
        for desired in fromlist:
            if (ch:=desired[0]) == '!':
                if desired == fromlist[0]:
                    actual_imports = set(export)
                ch2 = desired[1]
                if ch2 == ':':
                    tag = desired[2:]
                    if tag in export_tags:
                        for e in export_tags[tag][0]:
                            actual_imports.discard(e)
                elif ch2 == '/':
                    pat = re.compile(desired[2:-1])
                    for e in (export + export_ok):
                        if re.search(pat, e):
                            actual_imports.discard(e)
                else:
                    actual_imports.discard(desired[1:])
            elif ch == ':':
                tag = desired[1:]
                if tag in export_tags:
                    for e in export_tags[tag][0]:
                        actual_imports.add(e)
                elif tag == 'DEFAULT':
                    actual_imports.update(set(export))
            elif ch == '/':
                pat = re.compile(desired[1:-1])
                for e in (export + export_ok):
                    if re.search(pat, e):
                        actual_imports.add(e)
            elif desired == '*':
                actual_imports.update(set(export))
            elif ch == '-' or not re.match(r'^[A-Za-z_][A-Za-z0-9_]*$', desired):
                pass
            else:
                actual_imports.add(desired)

        actual_imports = list(actual_imports)
        sig_map = {'$': '_v', '@': '_a', '%': '_h'}
        for i in range(len(actual_imports)):
            perl_name = actual_imports[i]
            sig = perl_name[0]
            if sig == '&':
                perl_name = perl_name[1:]
                if hasattr(mod, perl_name+'_'):
                    actual_imports[i] = perl_name+'_'
            elif sig in ('$', '@', '%'):
                perl_name = perl_name[1:]
                sm = sig_map[sig]
                if hasattr(mod, perl_name+sm):
                    actual_imports[i] = perl_name+sm
                elif hasattr(mod, perl_name+'_'):
                    actual_imports[i] = perl_name+'_'
            elif hasattr(mod, perl_name+'_'):
                actual_imports[i] = perl_name+'_'

    namespace = None
    if not hasattr(builtins, caller_package):
        _init_package(caller_package)
    namespace = getattr(builtins, caller_package)
    for imp in actual_imports:
        if hasattr(mod, imp):
            mi = getattr(mod, imp)
            globals[imp] = mi
            if namespace:
                setattr(namespace, imp, mi)

    return 1
