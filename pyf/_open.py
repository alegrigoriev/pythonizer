
def _create_fh_methods(fh):
    """Create special methods for filehandles"""
    try:
        fh.autoflush = types.MethodType(_autoflush, fh)
    except NameError:  # _autoflush is only brought in if we reference it
        pass
    return fh

def _open(file,mode,encoding=None,errors=None,checked=True,newline="\n"):
    """Replacement for perl built-in open function when the mode is known."""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        (mode, encoding, errors, newline) = _handle_open_pragma(mode, encoding, errors, newline)
    except NameError:
        pass
    try:
        if mode == '|-' or mode == '|-b':    # pipe to
            text = True if mode == '|-' else False
            sp = subprocess.Popen(file, stdin=subprocess.PIPE, shell=_need_sh(file), text=text, encoding=encoding, errors=errors)
            if sp.returncode:
                raise Die(f"open(|{file}): failed with {sp.returncode}")
            sp.stdin._sp = sp           # issue 72
            sp.stdin._file = f"|{file}" # issue 72
            return sp.stdin
        elif mode == '-|' or mode == '-|b':  # pipe from
            text = True if mode == '-|' else False
            sp = subprocess.Popen(file, stdout=subprocess.PIPE, shell=_need_sh(file), text=text, encoding=encoding, errors=errors)
            if sp.returncode:
                raise Die(f"open({file}|): failed with {sp.returncode}")
            sp.stdout._sp = sp          # issue 72
            sp.stdout._file = f"|{file}" # issue 72
            return sp.stdout
        if file is None:
            return tempfile.TemporaryFile(mode=mode, encoding=encoding)
        if os.name == 'nt' and file.startswith('/tmp/'):
            file = tempfile.gettempdir() + file[4:]
        if 'b' in mode:
            newline = None
        return _create_fh_methods(open(file,mode,encoding=encoding,errors=errors,newline=newline))
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"open({file}, {mode}) failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        if checked:     # e.g. used in if(...)
            return None
        fh = io.TextIOWrapper(io.BufferedIOBase())
        fh.close()
        return _create_fh_methods(fh)
