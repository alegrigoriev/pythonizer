
def _perl_print(*args, **kwargs):
    """Replacement for perl built-in print/say/warn functions.
    Note that by default this acts like 'say' in that it appends a newline.
    To prevent the newline, pass the end='' keyword argument.  To write
    to a different file, pass the file=... keyword argument.  To flush the output
    after writing, pass flush=True.  To replace the OUTPUT_FIELD_SEPARATOR, pass sep='...'.
    It returns 1 if successful"""
    global OS_ERROR, TRACEBACK, AUTODIE
    try:
        file = sys.stdout
        if 'file' in kwargs:
            file = kwargs['file']
            if file is None:
                raise Die('print() on unopened filehandle')
        if 'sep' not in kwargs:
            kwargs['sep'] = OUTPUT_FIELD_SEPARATOR
        if 'end' in kwargs:
            kwargs['end'] += OUTPUT_RECORD_SEPARATOR
        else:
            kwargs['end'] = "\n" + OUTPUT_RECORD_SEPARATOR
        if 'flush' not in kwargs and hasattr(file, '_autoflush'):
            kwargs['flush'] = file._autoflush
        print(*args, **kwargs)
        return 1        # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"print failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return ''       # False

