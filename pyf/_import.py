
def _import(globals, path, module=None, fromlist=None, version=None):
    """Handle use/require statement from perl"""
    if module is None:
        [path, module] = os.path.split(os.path.splitext(os.path.abspath(path))[0])
    if module in sys.modules and \
      hasattr((mod:=sys.modules[module]), '__file__') and \
      os.path.join(path, module) + '.py' == mod.__file__:
       pass
    else:
        try:
            sys.path.insert(0, path)
            mod = __import__(module, globals=globals, fromlist=['*'])
            sys.modules[module] = mod
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

    globals[module] = mod

    if fromlist is None:
        return                  # use X ();

    if not isinstance(fromlist, (list, tuple)):
        fromlist = [fromlist]

    actual_imports = set()
    export = mod.EXPORT if hasattr(mod, 'EXPORT') else ()
    export_ok = mod.EXPORT_OK if hasattr(mod, 'EXPORT_OK') else ()
    export_tags = mod.EXPORT_TAGS if hasattr(mod, 'EXPORT_TAGS') else ()

    if (fromlist[0] == '*' or fromlist[0] == ':all') and hasattr(mod, '__all__'):
        actual_imports = set(mod.__all__)
    #elif fromlist[0] == '*' and not hasattr(mod, 'EXPORT'):
        #for key in mod.__dict__.keys():
            #if key[0] != '_':
                #actual_imports.add(key)
    else:
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

    for imp in actual_imports:
        if hasattr(mod, imp):
            globals[imp] = getattr(mod, imp)
            if hasattr(builtins, '__PACKAGE__'):
                pkg = builtins.__PACKAGE__
                if hasattr(builtins, pkg):
                    namespace = builtins[pkg]
                    setattr(namespace, imp, getattr(mod, imp))

