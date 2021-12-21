
def _dup(file,mode,checked=True):
    """Replacement for perl built-in open function when the mode contains '&'."""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if isinstance(file, io.IOBase):     # file handle
            file.flush()
            return os.fdopen(os.dup(file.fileno()), mode, encoding=file.encoding, errors=file.errors)
        if re.match(r'\d+', file):
            file = int(file)
        elif file in _DUP_MAP:
            file = _DUP_MAP[file]
        return _create_fh_methods(os.fdopen(os.dup(file), mode))
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        if checked:
            return None
        fh = io.StringIO()
        fh.close()
        return _create_fh_methods(fh)

