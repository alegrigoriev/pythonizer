
def _binmode(file,mode='b',encoding=None,errors=None):
    """Handle binmode"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        file.flush()
        omode = file.mode
        if mode is None:
            mode = omode.replace('b', '')
        else:
            mode = omode + mode
        if encoding is None and 'b' not in mode:
            encoding = file.encoding
        if errors is None and 'b' not in mode:
            errors = file.errors
        return os.fdopen(os.dup(file.fileno()), mode, encoding=encoding, errors=errors)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return None

