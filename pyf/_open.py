
def _open(file,mode,encoding=None,errors=None):
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
        return open(file,mode,encoding=encoding,errors=errors)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        fh = io.StringIO()
        fh.close()
        return fh

