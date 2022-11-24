
def _dup(file,mode,checked=True,equals=False,encoding=None,errors=None):
    """Replacement for perl built-in open function when the mode contains '&'.  Keyword arg
    'checked' means the result will be checked.  Keyword arg 'equals' means that '&=' was specified,
    so skip the os.dup operation."""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        if isinstance(file, io.IOBase):     # file handle
            file.flush()
            if encoding is None:
                encoding = file.encoding
            if errors is None:
                errors = file.errors
            if equals:
                return os.fdopen(file.fileno(), mode, encoding=encoding, errors=errors)
            return os.fdopen(os.dup(file.fileno()), mode, encoding=encoding, errors=errors)
        if isinstance(file, int):
            pass
        elif (_m:=re.match(r'=?(\d+)', file)):
            file = int(_m.group(1))
        elif file in _DUP_MAP:
            file = _DUP_MAP[file]
        if equals:
            return _create_fh_methods(os.fdopen(file, mode, encoding=encoding, errors=errors))
        return _create_fh_methods(os.fdopen(os.dup(file), mode, encoding=encoding, errors=errors))
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"dup failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        if checked:
            return None
        fh = io.StringIO()
        fh.close()
        return _create_fh_methods(fh)

