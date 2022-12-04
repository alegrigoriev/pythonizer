
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
        try:
            print(*args, **kwargs)
        except TypeError as _t:
            if 'bytes-like' in str(_t):
                for k in ('sep', 'end'):
                    if k in kwargs:
                        kwargs[k] = bytes(kwargs[k], encoding="latin1", errors="ignore")
                for i in range(len(args)):
                    a = args[i]
                    file.write(bytes(a, encoding="latin1", errors="ignore"))
                    if i == len(args)-1:
                        if 'end' in kwargs:
                            file.write(kwargs['end'])
                    elif 'sep' in kwargs:
                        file.write(kwargs['sep'])
                if 'flush' in kwargs and kwargs['flush'] and hasattr(file, 'flush'):
                    file.flush()
        return 1        # True
    except Exception as _e:
        OS_ERROR = str(_e)
        if TRACEBACK:
            _cluck(f"print failed: {OS_ERROR}",skip=2)
        if AUTODIE:
            raise
        return ''       # False

