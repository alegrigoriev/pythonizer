
def _create_fh_methods(fh):
    """Create special methods for filehandles"""
    try:
        fh.autoflush = types.MethodType(_autoflush, fh)
    except NameError:  # _autoflush is only brought in if we reference it
        pass
    return fh

def _open(file,mode,encoding=None,errors=None,checked=True):
    """Replacement for perl built-in open function when the mode is known."""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if mode == '|-':    # pipe to
            sp = subprocess.Popen(file, stdin=subprocess.PIPE, shell=True, text=True, encoding=encoding, errors=errors)
            if sp.returncode:
                raise Die(f"open(|{file}): failed with {sp.returncode}")
            return sp.stdin
        elif mode == '-|':  # pipe from
            sp = subprocess.Popen(file, stdout=subprocess.PIPE, shell=True, text=True, encoding=encoding, errors=errors)
            if sp.returncode:
                raise Die(f"open({file}|): failed with {sp.returncode}")
            return sp.stdout
        if file is None:
            return tempfile.TemporaryFile(mode=mode, encoding=encoding)
        return _create_fh_methods(open(file,mode,encoding=encoding,errors=errors))
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        if checked:     # e.g. used in if(...)
            return None
        fh = io.TextIOWrapper(io.BufferedIOBase())
        fh.close()
        return _create_fh_methods(fh)
