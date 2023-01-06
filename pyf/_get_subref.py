
def _get_subref(ref):
    """Convert a sub reference to a callable sub.  'ref' may already
    be callable or it could be the name of the sub.  Returns None if
    the sub isn't callable"""
    if callable(ref):
        return ref
    if isinstance(ref, str):
        ref = ref.replace('::', '.').replace("'", '.')
        ld = ref.rfind('.')
        if ld == -1:
            def caller_globals():
                frame = inspect.currentframe()
                try:
                    caller_frame = frame.f_back
                    return caller_frame.f_globals
                finally:
                    del frame
            glb = caller_globals()
            if ref in _PYTHONIZER_KEYWORDS:
                ref += '_'
            if ref in glb:
                result = glb[ref]
                if callable(result):
                    return result
            packname = builtins.__PACKAGE__
            sub = ref
        else:
            packname = ref[0:ld]
            if packname == '':
                packname = 'main'
            sub = ref[ld+1:]

        if sub in _PYTHONIZER_KEYWORDS:
            sub += '_'
        if hasattr(builtins, packname):
            namespace = getattr(builtins, packname)
            if hasattr(namespace, sub):
                result = getattr(namespace, sub)
                if callable(result):
                    return result
    return None
