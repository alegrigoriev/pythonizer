
def _create_all_fh_methods(fh):
    """Create all special methods for OO filehandles"""
    methods=dict(autoflush=_autoflush,binmode=_binmode, close=_close, eof=_eof, 
                 fcntl=_fcntl, format_write=_format_write, getc=_getc,
                 getpos=_getpos, ioctl=_ioctl, input_line_number=_input_line_number, 
                 open=_IOFile_open, print_=_print, printf=_printf, say=_say, setpos=_setpos,
                 # READ is handled specially because of the output scalar: read=_read, 
                 stat=_stat, 
                 # SYSREAD needs to be handled like READ sysread=_sysread, 
                 sysseek=_sysseek, syswrite=_syswrite, 
                 truncate=_truncate, ungetc=_ungetc, write_=_write_,
                 )
    for method, func in methods.items():
        setattr(fh, method, types.MethodType(func, fh))

    return fh

def _IOFile(path=None, mode=None, perms=None):
    """Implementation of IO::File->new()"""
    global TRACEBACK, AUTODIE
    try:
        if path is None:
            fh = io.TextIOWrapper(io.BufferedIOBase())
            fh.close()
            return _create_all_fh_methods(fh)
        if perms is None:
            perms = 0o777
        #fh = os.fdopen(os.open(path, mode, perms))
        fh = _IOFile_open(path, mode, perms)
        return _create_all_fh_methods(fh)
    except Exception as e:
        if TRACEBACK:
            traceback.print_exc()
        if AUTODIE:
            raise
        fh = io.TextIOWrapper(io.BufferedIOBase())
        fh.close()
        return _create_all_fh_methods(fh)
