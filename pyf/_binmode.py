
def _binmode(fh,mode='b',encoding=None,errors=None):
    """Handle binmode"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        omode = ''
        fno = None
        try:
            fno = fh.fileno()
            fh.flush()      # could be a closed file
            omode = fh.mode # could not have a mode
        except Exception:
            pass
        if mode is None:
            mode = omode.replace('b', '')
        else:
            mode = omode + mode
        if encoding is None and 'b' not in mode:
            encoding = fh.encoding
        if errors is None and 'b' not in mode:
            errors = fh.errors
        if fno is None:
            result = io.TextIOWrapper(io.BufferedIOBase(), encoding=encoding, errors=errors)
        else:
            result = os.fdopen(os.dup(fno), mode, encoding=encoding, errors=errors)
        if hasattr(fh, 'filename') and hasattr(fh, '_name'):   # from tempfile
            result.filename = fh.filename
            result._name = fh._name
        if hasattr(fh, 'say'):        # from IO::File
            return _create_all_fh_methods(fh)
        return result
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"binmode failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return None

