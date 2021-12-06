
def _binmode(file,mode=None,encoding=None,errors=None):
    """Handle binmode"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        file.flush()
        omode = file.mode
        if mode is None:
            mode = omode.replace('b', '')
        else:
            mode = omode + mode
        if encoding is None:
            encoding = file.encoding
        if errors is None:
            errors = file.errors
        return os.fdopen(os.dup(file.fileno()), mode, encoding=encoding, errors=errors)
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        return None

